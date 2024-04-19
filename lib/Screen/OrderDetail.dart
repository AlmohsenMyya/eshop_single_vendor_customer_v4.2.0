import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:eshop/Helper/ApiBaseHelper.dart';
import 'package:eshop/Helper/Session.dart';
import 'package:eshop/Model/Order_Model.dart';
import 'package:eshop/Model/Section_Model.dart';
import 'package:eshop/Provider/CartProvider.dart';
import 'package:eshop/Screen/Cart.dart';
import 'package:eshop/Screen/Review_Gallary.dart';
import 'package:eshop/Screen/Review_Preview.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../Helper/Color.dart';
import '../Helper/String.dart';
import '../Model/User.dart';
import '../Provider/UserProvider.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/widgets/AppBtn.dart';
import '../ui/widgets/SimpleAppBar.dart';
import 'HomePage.dart';

class OrderDetail extends StatefulWidget {
  final OrderModel? model;
  final int? index;

  const OrderDetail({Key? key, this.model, this.index}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StateOrder();
  }
}

class StateOrder extends State<OrderDetail>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  ScrollController controller = ScrollController();
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;
  List<User> tempList = [];
  late bool _isCancleable, _isReturnable;
  bool _isProgress = false;
  int offset = 0;
  int total = 0;
  List<User> reviewList = [];
  bool isLoadingmore = true;
  bool _isReturnClick = true;
  String? proId, image;
  final InAppReview _inAppReview = InAppReview.instance;
  List<File> files = [];

  int _selectedTabIndex = 0;
  late TabController _tabController;

  List<File> reviewPhotos = [];
  TextEditingController commentTextController = TextEditingController();
  double curRating = 0.0;
  String currentLinkForDownload = '';

  List<String> statusList = [
    "awaiting",
    "received",
    "processed",
    "shipped",
    "delivered",
    "cancelled",
    "returned"
  ];

  @override
  void initState() {
    super.initState();
    files.clear();
    reviewPhotos.clear();
    FlutterDownloader.registerCallback(downloadCallback);
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
    _tabController = TabController(
      length: 6,
      vsync: this,
    );
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }

  static void downloadCallback(
    String id,
    int status,
    int progress,
  ) {
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port')!;
    send.send([id, status, progress]);
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
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;

    var model = widget.model!;
    String? pDate, prDate, sDate, dDate, cDate, rDate;

    if (model.listStatus.contains(PLACED)) {
      pDate = model.listDate![model.listStatus.indexOf(PLACED)];

      List d = pDate.split(" ");
      pDate = d[0] + "\n" + d[1];
    }
    if (model.listStatus.contains(PROCESSED)) {
      prDate = model.listDate![model.listStatus.indexOf(PROCESSED)];
      List d = prDate.split(" ");
      prDate = d[0] + "\n" + d[1];
    }
    if (widget.model!.isLocalPickUp != "1") {
      if (model.listStatus.contains(SHIPED)) {
        sDate = model.listDate![model.listStatus.indexOf(SHIPED)];
        List d = sDate.split(" ");
        sDate = d[0] + "\n" + d[1];
      }
    } else {
      if (model.listStatus.contains(READY_TO_PICKUP)) {
        sDate = model.listDate![model.listStatus.indexOf(READY_TO_PICKUP)];
        List d = sDate.split(" ");
        sDate = d[0] + "\n" + d[1];
      }
    }
    if (model.listStatus.contains(DELIVERD)) {
      dDate = model.listDate![model.listStatus.indexOf(DELIVERD)];
      List d = dDate.split(" ");
      dDate = d[0] + "\n" + d[1];
    }
    if (model.listStatus.contains(CANCLED)) {
      cDate = model.listDate![model.listStatus.indexOf(CANCLED)];
      List d = cDate.split(" ");
      cDate = d[0] + "\n" + d[1];
    }
    if (model.listStatus.contains(RETURNED)) {
      rDate = model.listDate![model.listStatus.indexOf(RETURNED)];
      List d = rDate.split(" ");
      rDate = d[0] + "\n" + d[1];
    }

    _isCancleable = model.isCancleable == "1" ? true : false;
    _isReturnable = model.isReturnable == "1" ? true : false;

    return PopScope(
      canPop: _selectedTabIndex == 0,
      onPopInvoked: (_) {
        if (_tabController.index != 0) {
          _tabController.animateTo(0);
        }
      },
      child: Scaffold(
        appBar:
            getSimpleAppBar(getTranslated(context, "ORDER_DETAIL")!, context),
        body: _isNetworkAvail
            ? Stack(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: getSubHeadingsTabBar(),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            getOrderDetails(model),
                            SingleChildScrollView(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: getSingleProduct(model, PROCESSED),
                              ),
                            ),
                            SingleChildScrollView(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: getSingleProduct(model, SHIPED),
                              ),
                            ),
                            SingleChildScrollView(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: getSingleProduct(model, DELIVERD),
                              ),
                            ),
                            SingleChildScrollView(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: getSingleProduct(model, CANCLED),
                              ),
                            ),
                            SingleChildScrollView(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: getSingleProduct(model, RETURNED),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  showCircularProgress(_isProgress, colors.primary),
                ],
              )
            : noInternet(context),
      ),
    );
  }

  priceDetails(OrderModel model) {
    return Card(
        elevation: 0,
        child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding:
                      const EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                  child: Text(getTranslated(context, 'PRICE_DETAIL')!,
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: Theme.of(context).colorScheme.fontColor,
                          fontWeight: FontWeight.bold))),
              Divider(
                color: Theme.of(context).colorScheme.lightBlack,
              ),
              Padding(
                padding:
                    const EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${getTranslated(context, 'PRICE_LBL')!} :",
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack2)),
                    Text(
                        getPriceFormat(
                            context, double.parse(widget.model!.subTotal!))!,
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack2))
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${getTranslated(context, 'TAXPER')!} :",
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack2)),
                    Text(
                        "+ ${getPriceFormat(context, double.parse(widget.model!.taxAmt!))!}",
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack2))
                  ],
                ),
              ),
              if (model.itemList![0].productType != 'digital_product')
                Padding(
                  padding:
                      const EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${getTranslated(context, 'DELIVERY_CHARGE')!} :",
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge!
                              .copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .lightBlack2)),
                      Text(
                          '+ ${getPriceFormat(context, double.parse(widget.model!.delCharge!))!}',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge!
                              .copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .lightBlack2))
                    ],
                  ),
                ),
              Padding(
                padding:
                    const EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${getTranslated(context, 'PROMO_CODE_DIS_LBL')!} :",
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack2)),
                    Text(
                        '- ${getPriceFormat(context, double.parse(widget.model!.promoDis!))!}',
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack2))
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${getTranslated(context, 'WALLET_BAL')!} :",
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack2)),
                    Text(
                        '-${getPriceFormat(context, double.parse(widget.model!.walBal!))!}',
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack2))
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsetsDirectional.only(start: 15.0, end: 15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${getTranslated(context, 'PAYABLE')!} :",
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                              color: Theme.of(context).colorScheme.lightBlack2,
                            )),
                    Text(
                        getPriceFormat(
                            context, double.parse(widget.model!.payable!))!,
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                              color: Theme.of(context).colorScheme.lightBlack2,
                            ))
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                    start: 15.0, end: 15.0, top: 5.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${getTranslated(context, 'FINAL_TOTAL_LBL')!} :",
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack,
                            fontWeight: FontWeight.bold)),
                    Text(
                        getPriceFormat(
                            context, double.parse(widget.model!.total!))!,
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack,
                            fontWeight: FontWeight.bold))
                  ],
                ),
              ),
            ])));
  }

  pickUpTimeDetails() {
    return widget.model!.pickTime != ""
        ? Card(
            elevation: 0,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(getTranslated(context, 'ESTIMATE_TIME_LBL')!,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.fontColor)),
                  Text(widget.model!.pickTime!)
                ]),
          )
        : const SizedBox();
  }

  sellerNotesDetails() {
    return widget.model!.sellerNotes != ""
        ? Card(
            elevation: 0,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(getTranslated(context, 'SELLER_NOTES_LBL')!,
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: Theme.of(context).colorScheme.fontColor)),
                  Text(widget.model!.sellerNotes!)
                ]),
          )
        : const SizedBox();
  }

  shippingDetails() {
    if (widget.model!.isLocalPickUp != "1") {
      return Card(
          elevation: 0,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                        padding: const EdgeInsetsDirectional.only(
                            start: 15.0, end: 15.0),
                        child: Text(getTranslated(context, 'SHIPPING_DETAIL')!,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall!
                                .copyWith(
                                    color:
                                        Theme.of(context).colorScheme.fontColor,
                                    fontWeight: FontWeight.bold))),
                    Divider(
                      color: Theme.of(context).colorScheme.lightBlack,
                    ),
                    Padding(
                        padding: const EdgeInsetsDirectional.only(
                            start: 15.0, end: 15.0),
                        child: Text(
                          "${widget.model!.recname!},",
                        )),
                    Padding(
                        padding: const EdgeInsetsDirectional.only(
                            start: 15.0, end: 15.0),
                        child: Text(widget.model!.address!,
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .lightBlack2))),
                    Padding(
                        padding: const EdgeInsetsDirectional.only(
                            start: 15.0, end: 15.0),
                        child: Text(widget.model!.recContact!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.lightBlack2,
                            ))),
                  ])));
    } else {
      return Card(
          elevation: 0,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 15.0, 0, 15.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                        padding: const EdgeInsetsDirectional.only(
                            start: 15.0, end: 15.0),
                        child: Text(
                            getTranslated(context, 'SELLER_DETAILS_LBL')!,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall!
                                .copyWith(
                                    color:
                                        Theme.of(context).colorScheme.fontColor,
                                    fontWeight: FontWeight.bold))),
                    Divider(
                      color: Theme.of(context).colorScheme.lightBlack,
                    ),
                    ADMIN_ADDRESS != ""
                        ? Padding(
                            padding: const EdgeInsetsDirectional.only(
                                start: 15.0, end: 15.0),
                            child: Text(ADMIN_ADDRESS,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .lightBlack2)))
                        : const SizedBox(),
                    Padding(
                        padding: const EdgeInsetsDirectional.only(
                            start: 15.0, end: 15.0, top: 15),
                        child: Row(
                          children: [
                            Expanded(
                                child: CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      _launchMap(ADMIN_LAT, ADMIN_LONG);
                                    },
                                    child: Container(
                                        height: 40,
                                        alignment: FractionalOffset.center,
                                        decoration: const BoxDecoration(
                                          color: colors.primary,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5.0)),
                                        ),
                                        child: Text(
                                            getTranslated(
                                                context, 'GET_SHOP_DIRE_LBL')!,
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall!
                                                .copyWith(
                                                    color: colors.whiteTemp,
                                                    fontWeight:
                                                        FontWeight.normal))))),
                            const SizedBox(
                              width: 25,
                            ),
                            Expanded(
                                child: CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      _launchCaller(ADMIN_MOB);
                                    },
                                    child: Container(
                                        height: 40,
                                        alignment: FractionalOffset.center,
                                        decoration: const BoxDecoration(
                                          color: colors.primary,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(5.0)),
                                        ),
                                        child: Text(
                                            getTranslated(
                                                context, 'CALL_TO_SELLER_LBL')!,
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall!
                                                .copyWith(
                                                    color: colors.whiteTemp,
                                                    fontWeight:
                                                        FontWeight.normal))))),
                          ],
                        )),
                  ])));
    }
  }

  _launchCaller(String mobile) async {
    var url = "tel:$mobile";
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  _launchMap(lat, lng) async {
    var url = '';

    if (Platform.isAndroid) {
      url =
          "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving&dir_action=navigate";
    } else {
      url =
          "http://maps.apple.com/?saddr=&daddr=$lat,$lng&directionsmode=driving&dir_action=navigate";
    }
    await launchUrlString(url, mode: LaunchMode.externalApplication);
  }

  productItem(OrderItem orderItem, OrderModel model) {
    String? pDate,
        prDate,
        sDate,
        dDate,
        cDate,
        rDate,
        aDate,
        repDate,
        reapDate,
        redDate;

    if (orderItem.listStatus!.contains(WAITING)) {
      aDate = orderItem.listDate![orderItem.listStatus!.indexOf(WAITING)];
    }
    if (orderItem.listStatus!.contains(PLACED)) {
      pDate = orderItem.listDate![orderItem.listStatus!.indexOf(PLACED)];
    }
    if (orderItem.listStatus!.contains(PROCESSED)) {
      prDate = orderItem.listDate![orderItem.listStatus!.indexOf(PROCESSED)];
    }
    if (widget.model!.isLocalPickUp != "1") {
      if (orderItem.listStatus!.contains(SHIPED)) {
        sDate = orderItem.listDate![orderItem.listStatus!.indexOf(SHIPED)];
      }
    } else {
      if (orderItem.listStatus!.contains(READY_TO_PICKUP)) {
        sDate =
            orderItem.listDate![orderItem.listStatus!.indexOf(READY_TO_PICKUP)];
      }
    }
    if (orderItem.listStatus!.contains(DELIVERD)) {
      dDate = orderItem.listDate![orderItem.listStatus!.indexOf(DELIVERD)];
    }
    if (orderItem.listStatus!.contains(CANCLED)) {
      cDate = orderItem.listDate![orderItem.listStatus!.indexOf(CANCLED)];
    }
    if (orderItem.listStatus!.contains(RETURNED)) {
      rDate = orderItem.listDate![orderItem.listStatus!.indexOf(RETURNED)];
    }
    if (orderItem.listStatus!.contains(RETURN_REQ_PENDING)) {
      repDate = orderItem
          .listDate![orderItem.listStatus!.indexOf(RETURN_REQ_PENDING)];
    }
    if (orderItem.listStatus!.contains(RETURN_REQ_APPROVED)) {
      reapDate = orderItem
          .listDate![orderItem.listStatus!.indexOf(RETURN_REQ_APPROVED)];
    }
    if (orderItem.listStatus!.contains(RETURN_REQ_DECLINE)) {
      redDate = orderItem
          .listDate![orderItem.listStatus!.indexOf(RETURN_REQ_DECLINE)];
    }
    List att = [], val = [];
    if (orderItem.attr_name!.isNotEmpty) {
      att = orderItem.attr_name!.split(',');
      val = orderItem.varient_values!.split(',');
    }

    int caclabelTillIndex =
        statusList.indexWhere((element) => element == orderItem.canclableTill);

    int curStatusIndex =
        statusList.indexWhere((element) => element == orderItem.status);

    return Card(
        elevation: 0,
        child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    ClipRRect(
                        borderRadius: BorderRadius.circular(7.0),
                        child: networkImageCommon(orderItem.image!, 90, false,
                            height: 90,
                            width:
                                90) /*CachedNetworkImage(
                          fadeInDuration: const Duration(milliseconds: 150),
                          imageUrl: orderItem.image!,
                          height: 90.0,
                          width: 90.0,
                          fit: BoxFit.cover,
                          errorWidget: (context, error, stackTrace) =>
                              erroWidget(90),
                          placeholder: (context,url) {return placeHolder(90);}
                        )*/
                        ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              orderItem.name!,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .lightBlack,
                                      fontWeight: FontWeight.normal),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            orderItem.attr_name!.isNotEmpty
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
                                                        .lightBlack2),
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
                                                        .lightBlack),
                                          ),
                                        )
                                      ]);
                                    })
                                : const SizedBox.shrink(),
                            Row(children: [
                              Text(
                                "${getTranslated(context, 'QUANTITY_LBL')!}:",
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall!
                                    .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .lightBlack2),
                              ),
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    start: 5.0),
                                child: Text(
                                  orderItem.qty!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall!
                                      .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .lightBlack),
                                ),
                              )
                            ]),
                            Text(
                              getPriceFormat(
                                  context, double.parse(orderItem.price!))!,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                Divider(
                  color: Theme.of(context).colorScheme.lightBlack,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      pDate != null ? getPlaced(pDate) : getPlaced(aDate ?? ""),
                      orderItem.productType == 'digital_product'
                          ? const SizedBox.shrink()
                          : getProcessed(prDate, cDate),
                      orderItem.productType == 'digital_product'
                          ? const SizedBox.shrink()
                          : getShipped(sDate, cDate),
                      orderItem.productType == 'digital_product'
                          ? const SizedBox.shrink()
                          : getDelivered(dDate, cDate),
                      getDigitalDelivered(orderItem, dDate, cDate),
                      getCanceled(cDate),
                      getReturneRequestPending(orderItem, repDate),
                      getReturneRequestApproved(orderItem, reapDate),
                      getReturneRequestDecline(orderItem, redDate),
                      getReturned(orderItem, rDate, model),
                    ],
                  ),
                ),
                orderItem.downloadAllowed == '1'
                    ? downloadProductFile(context, orderItem.id!, orderItem)
                    : const SizedBox.shrink(),
                Divider(
                  color: Theme.of(context).colorScheme.lightBlack,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (orderItem.status == DELIVERD)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            openBottomSheet(context, orderItem);
                          },
                          icon: const Icon(Icons.rate_review_outlined),
                          label: Text(
                            orderItem.userReviewRating != "0"
                                ? getTranslated(context, "UPDATE_REVIEW_LBL")!
                                : getTranslated(context, "WRITE_REVIEW_LBL")!,
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Theme.of(context).colorScheme.btnColor),
                          ),
                        ),
                      ),
                    if (!orderItem.listStatus!.contains(DELIVERD) &&
                        (!orderItem.listStatus!.contains(RETURNED)) &&
                        orderItem.isCancle == "1" &&
                        orderItem.isAlrCancelled == "0" &&
                        curStatusIndex <= caclabelTillIndex)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Align(
                            alignment: Alignment.bottomRight,
                            child: OutlinedButton(
                              onPressed: _isReturnClick
                                  ? () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text(
                                              getTranslated(
                                                  context, 'ARE_YOU_SURE?')!,
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .fontColor),
                                            ),
                                            content: Text(
                                              getTranslated(context,
                                                  'WOULD_LIKE_TO_CANCEL_PRO_LBL')!,
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .fontColor),
                                            ),
                                            actions: [
                                              TextButton(
                                                child: Text(
                                                  getTranslated(
                                                      context, 'YES')!,
                                                  style: const TextStyle(
                                                      color: colors.primary),
                                                ),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  setState(() {
                                                    _isReturnClick = false;
                                                    _isProgress = true;
                                                  });
                                                  cancelOrder(
                                                      CANCLED,
                                                      updateOrderItemApi,
                                                      orderItem.id);
                                                },
                                              ),
                                              TextButton(
                                                child: Text(
                                                  getTranslated(context, 'NO')!,
                                                  style: const TextStyle(
                                                      color: colors.primary),
                                                ),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                              )
                                            ],
                                          );
                                        },
                                      );
                                    }
                                  : null,
                              child:
                                  Text(getTranslated(context, 'ITEM_CANCEL')!),
                            )),
                      )
                    else
                      ((orderItem.listStatus!.contains(DELIVERD) &&
                                  orderItem.productType != 'digital_product') &&
                              orderItem.isReturn == "1" &&
                              orderItem.isAlrReturned == "0" &&
                              (!orderItem.listStatus!
                                      .contains(RETURN_REQ_DECLINE) &&
                                  !orderItem.listStatus!
                                      .contains(RETURN_REQ_APPROVED) &&
                                  !orderItem.listStatus!
                                      .contains(RETURN_REQ_PENDING)))
                          ? Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: OutlinedButton(
                                onPressed: _isReturnClick
                                    ? () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text(
                                                getTranslated(
                                                    context, 'ARE_YOU_SURE?')!,
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .fontColor),
                                              ),
                                              content: Text(
                                                getTranslated(context,
                                                    'WOULD_LIKE_TO_RETURN_PRO_LBL')!,
                                                style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .fontColor),
                                              ),
                                              actions: [
                                                TextButton(
                                                  child: Text(
                                                    getTranslated(
                                                        context, 'YES')!,
                                                    style: const TextStyle(
                                                        color: colors.primary),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    setState(() {
                                                      _isReturnClick = false;
                                                      _isProgress = true;
                                                    });
                                                    cancelOrder(
                                                        RETURNED,
                                                        updateOrderItemApi,
                                                        orderItem.id);
                                                  },
                                                ),
                                                TextButton(
                                                  child: Text(
                                                    getTranslated(
                                                        context, 'NO')!,
                                                    style: const TextStyle(
                                                        color: colors.primary),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                )
                                              ],
                                            );
                                          },
                                        );
                                      }
                                    : null,
                                child: Text(
                                    getTranslated(context, 'ITEM_RETURN')!),
                              ),
                            )
                          : const SizedBox.shrink(),
                  ],
                ),
              ],
            )));
  }

  bankProof(OrderModel model) {
    String status = model.attachList![0].bankTranStatus!;
    Color clr;
    if (status == "0") {
      status = "Pending";
      clr = Colors.cyan;
    } else if (status == "1") {
      status = "Rejected";
      clr = Colors.red;
    } else {
      status = "Accepted";
      clr = Colors.green;
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: model.attachList!.length,
              itemBuilder: (context, i) {
                return Padding(
                  padding: const EdgeInsetsDirectional.only(
                      top: 8.0, bottom: 8, end: 8),
                  child: InkWell(
                    child: Text(
                      "Attachment ${i + 1}",
                      style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Theme.of(context).colorScheme.fontColor),
                    ),
                    onTap: () {
                      _launchURL(model.attachList![i].attachment!);
                    },
                  ),
                );
              },
            ),
          ),
        ),
        Container(
            decoration: BoxDecoration(
                color: clr, borderRadius: BorderRadius.circular(5)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 5),
              child: Text(status),
            ))
      ],
    );
  }

  prescriptionAttachments(OrderModel model) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: model.orderPrescriptionAttachments!.length > 5
                  ? 5
                  : model.orderPrescriptionAttachments!.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsetsDirectional.only(
                      top: 8.0, bottom: 8, end: 8),
                  child: InkWell(
                    onTap: () async {
                      if (index == 4) {
                        Navigator.push(
                            context,
                            CupertinoPageRoute(
                                builder: (context) => ReviewGallary(
                                      orderModel: model,
                                      imageList:
                                          model.orderPrescriptionAttachments,
                                    )));
                      } else {
                        Navigator.push(
                            context,
                            PageRouteBuilder(
                                pageBuilder: (_, __, ___) => ReviewPreview(
                                      index: index,
                                      imageList:
                                          model.orderPrescriptionAttachments,
                                    )));
                      }
                    },
                    child: Stack(
                      children: [
                        networkImageCommon(
                            model.orderPrescriptionAttachments![index],
                            80,
                            false,
                            height: 100,
                            width: 80),
                        /*CachedNetworkImage(
                          fadeInDuration: const Duration(milliseconds: 150),
                          imageUrl:
                              model.orderPrescriptionAttachments![index],
                          height: 100.0,
                          width: 80.0,
                          fit: BoxFit.cover,
                          placeholder: (context,url) {return placeHolder(80);},
                          errorWidget: (context, error, stackTrace) =>
                              erroWidget(80),
                        ),*/
                        index == 4
                            ? Container(
                                height: 100.0,
                                width: 80.0,
                                color: colors.black54,
                                child: Center(
                                    child: Text(
                                  "+${model.orderPrescriptionAttachments!.length - 5}",
                                  style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.white,
                                      fontWeight: FontWeight.bold),
                                )),
                              )
                            : const SizedBox.shrink()
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _launchURL(String url) async => await canLaunchUrlString(url)
      ? await launchUrlString(url)
      : throw 'Could not launch $url';

  _imgFromGallery() async {
    try {
      var result = await FilePicker.platform
          .pickFiles(allowMultiple: false, type: FileType.image);
      if (result != null) {
        files = result.paths.map((path) => File(path!)).toList();
        if (mounted) setState(() {});
      } else {
        // User canceled the picker
      }
    } catch (e) {
      setSnackbar(getTranslated(context, "PERMISSION_NOT_ALLOWED")!, context);
    }
  }

  getPlaced(String pDate) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Icon(
          Icons.circle,
          color: colors.primary,
          size: 15,
        ),
        Container(
          margin: const EdgeInsetsDirectional.only(start: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                getTranslated(context, 'ORDER_NPLACED')!,
                style: const TextStyle(fontSize: 8),
              ),
              Text(
                pDate,
                style: const TextStyle(fontSize: 8),
              ),
            ],
          ),
        ),
      ],
    );
  }

  getProcessed(String? prDate, String? cDate) {
    return cDate == null
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                      height: 30,
                      child: VerticalDivider(
                        thickness: 2,
                        color: prDate == null ? Colors.grey : colors.primary,
                      )),
                  Icon(
                    Icons.circle,
                    color: prDate == null ? Colors.grey : colors.primary,
                    size: 15,
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsetsDirectional.only(start: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getTranslated(context, 'ORDER_PROCESSED')!,
                      style: const TextStyle(fontSize: 8),
                    ),
                    Text(
                      prDate ?? " ",
                      style: const TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ),
            ],
          )
        : prDate == null
            ? const SizedBox.shrink()
            : Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 30,
                        child: VerticalDivider(
                          thickness: 2,
                          color: colors.primary,
                        ),
                      ),
                      Icon(
                        Icons.circle,
                        color: colors.primary,
                        size: 15,
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsetsDirectional.only(start: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getTranslated(context, 'ORDER_PROCESSED')!,
                          style: const TextStyle(fontSize: 8),
                        ),
                        Text(
                          prDate,
                          style: const TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                ],
              );
  }

  getShipped(String? sDate, String? cDate) {
    return cDate == null
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: VerticalDivider(
                      thickness: 2,
                      color: sDate == null ? Colors.grey : colors.primary,
                    ),
                  ),
                  Icon(
                    Icons.circle,
                    color: sDate == null ? Colors.grey : colors.primary,
                    size: 15,
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsetsDirectional.only(start: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.model!.isLocalPickUp != "1"
                          ? getTranslated(context, 'ORDER_SHIPPED')!
                          : getTranslated(context, 'READY_TO_SHIP_LBL')!,
                      style: const TextStyle(fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      sDate ?? " ",
                      style: const TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ),
            ],
          )
        : sDate == null
            ? const SizedBox.shrink()
            : Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Column(
                    children: [
                      SizedBox(
                        height: 30,
                        child: VerticalDivider(
                          thickness: 2,
                          color: colors.primary,
                        ),
                      ),
                      Icon(
                        Icons.circle,
                        color: colors.primary,
                        size: 15,
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsetsDirectional.only(start: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getTranslated(context, 'ORDER_SHIPPED')!,
                          style: const TextStyle(fontSize: 8),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          sDate,
                          style: const TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                ],
              );
  }

  getDelivered(String? dDate, String? cDate) {
    return cDate == null
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: VerticalDivider(
                      thickness: 2,
                      color: dDate == null ? Colors.grey : colors.primary,
                    ),
                  ),
                  Icon(
                    Icons.circle,
                    color: dDate == null ? Colors.grey : colors.primary,
                    size: 15,
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsetsDirectional.only(start: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.model!.isLocalPickUp != "1"
                          ? getTranslated(context, 'ORDER_DELIVERED')!
                          : getTranslated(context, 'PICKED_UP_LBL')!,
                      style: const TextStyle(fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      dDate ?? " ",
                      style: const TextStyle(fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          )
        : const SizedBox.shrink();
  }

  getDigitalDelivered(OrderItem orderItem, String? dDate, String? cDate) {
    return Column(children: [
      orderItem.productType == 'digital_product'
          ? orderItem.downloadAllowed == '1'
              ? cDate == null
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          children: [
                            SizedBox(
                              height: 30,
                              child: VerticalDivider(
                                thickness: 2,
                                color: dDate == null
                                    ? Colors.grey
                                    : colors.primary,
                              ),
                            ),
                            Icon(
                              Icons.circle,
                              color:
                                  dDate == null ? Colors.grey : colors.primary,
                              size: 15,
                            ),
                          ],
                        ),
                        Container(
                          margin: const EdgeInsetsDirectional.only(start: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                getTranslated(context, 'ORDER_DELIVERED')!,
                                style: const TextStyle(fontSize: 8),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                dDate ?? " ",
                                style: const TextStyle(fontSize: 8),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink()
              : const SizedBox.shrink()
          : const SizedBox.shrink(),
      orderItem.productType == 'digital_product'
          ? orderItem.downloadAllowed != '1'
              ? cDate == null
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          children: [
                            SizedBox(
                              height: 30,
                              child: VerticalDivider(
                                thickness: 2,
                                color: dDate == null
                                    ? Colors.grey
                                    : colors.primary,
                              ),
                            ),
                            Icon(
                              Icons.circle,
                              color:
                                  dDate == null ? Colors.grey : colors.primary,
                              size: 15,
                            ),
                          ],
                        ),
                        Container(
                          margin: const EdgeInsetsDirectional.only(start: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                getTranslated(context, 'ORDER_DELIVERED')!,
                                style: const TextStyle(fontSize: 8),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                dDate ?? " ",
                                style: const TextStyle(fontSize: 8),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                getTranslated(context, 'CHECK_MAIL_INTRO_LBL')!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 8),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink()
              : const SizedBox.shrink()
          : const SizedBox.shrink(),
    ]);
  }

  getCanceled(String? cDate) {
    return cDate != null
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: VerticalDivider(
                      thickness: 2,
                      color: colors.primary,
                    ),
                  ),
                  Icon(
                    Icons.cancel_rounded,
                    color: colors.primary,
                    size: 15,
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsetsDirectional.only(start: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getTranslated(context, 'ORDER_CANCLED')!,
                      style: const TextStyle(fontSize: 8),
                    ),
                    Text(
                      cDate,
                      style: const TextStyle(fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          )
        : const SizedBox.shrink();
  }

  getReturned(OrderItem item, String? rDate, OrderModel model) {
    return item.listStatus!.contains(RETURNED)
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: VerticalDivider(
                      thickness: 2,
                      color: colors.primary,
                    ),
                  ),
                  Icon(
                    Icons.cancel_rounded,
                    color: colors.primary,
                    size: 15,
                  ),
                ],
              ),
              Container(
                  margin: const EdgeInsetsDirectional.only(start: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        getTranslated(context, 'ORDER_RETURNED')!,
                        style: const TextStyle(fontSize: 8),
                      ),
                      Text(
                        rDate ?? " ",
                        style: const TextStyle(fontSize: 8),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )),
            ],
          )
        : const SizedBox.shrink();
  }

  getReturneRequestPending(
    OrderItem item,
    String? repDate,
  ) {
    return item.listStatus!.contains(RETURN_REQ_PENDING)
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: VerticalDivider(
                      thickness: 2,
                      color: colors.primary,
                    ),
                  ),
                  Icon(
                    Icons.pending,
                    color: colors.primary,
                    size: 15,
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsetsDirectional.only(start: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getTranslated(context, 'RETURN_REQUEST_PENDING_LBL')!,
                      style: const TextStyle(fontSize: 8),
                    ),
                    Text(
                      repDate ?? ' ',
                      style: const TextStyle(fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          )
        : const SizedBox();
  }

  getReturneRequestApproved(
    OrderItem item,
    String? reapDate,
  ) {
    return item.listStatus!.contains(RETURN_REQ_APPROVED)
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: VerticalDivider(
                      thickness: 2,
                      color: colors.primary,
                    ),
                  ),
                  Icon(
                    Icons.approval,
                    color: colors.primary,
                    size: 15,
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsetsDirectional.only(start: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getTranslated(context, 'RETURN_REQUEST_APPROVED_LBL')!,
                      style: const TextStyle(fontSize: 8),
                    ),
                    Text(
                      reapDate ?? ' ',
                      style: const TextStyle(fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          )
        : const SizedBox();
  }

  getReturneRequestDecline(
    OrderItem item,
    String? redDate,
  ) {
    return item.listStatus!.contains(RETURN_REQ_DECLINE)
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: VerticalDivider(
                      thickness: 2,
                      color: colors.primary,
                    ),
                  ),
                  Icon(
                    Icons.cancel_rounded,
                    color: colors.primary,
                    size: 15,
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsetsDirectional.only(start: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getTranslated(context, 'RETURN_REQUEST_DECLINE_LBL')!,
                      style: const TextStyle(fontSize: 8),
                    ),
                    Text(
                      redDate ?? ' ',
                      style: const TextStyle(fontSize: 8),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          )
        : const SizedBox();
  }

  Future<void> cancelOrder(String status, Uri api, String? id) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {ORDERID: id, STATUS: status};
        apiBaseHelper.postAPICall(api, parameter).then((getdata) {
          bool error = getdata["error"];
          String msg = getdata["message"];

          if (!error) {
            Future.delayed(const Duration(seconds: 1)).then((_) async {
              Navigator.pop(context, 'update');
            });
          }

          if (mounted) {
            setState(() {
              _isProgress = false;
              _isReturnClick = true;
            });
          }
          if (mounted) {
            setSnackbar(msg, context);
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
          _isReturnClick = true;
        });
      }
    }
  }

  Future<bool> checkPermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      var result = await Permission.storage.request();
      if (result.isGranted) {
        return true;
      } else {
        return false;
      }
    } else {
      return true;
    }
  }

  downloadInvoice() {
    print("widget invoice******${widget.model!.invoice}");
    return widget.model!.invoice != ""
        ? Card(
            elevation: 0,
            child: InkWell(
                child: ListTile(
                  dense: true,
                  trailing: const Icon(
                    Icons.keyboard_arrow_right,
                    color: colors.primary,
                  ),
                  leading: const Icon(
                    Icons.receipt,
                    color: colors.primary,
                  ),
                  title: Text(
                    getTranslated(context, 'DWNLD_INVOICE')!,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: Theme.of(context).colorScheme.lightBlack),
                  ),
                ),
                onTap: () async {
                  final status = await Permission.storage.request();
                  var response = await apiBaseHelper.postAPICall(
                      getInvoiceHTML, {"order_id": widget.model!.id!});

                  bool isLatestOs = false;
                  if (Platform.isAndroid) {
                    var androidInfo = await DeviceInfoPlugin().androidInfo;
                    var release = androidInfo.version.release;
                    isLatestOs =
                        num.parse(release) > 12; //13 working without permission
                  }

                  if (status == PermissionStatus.granted || isLatestOs) {
                    if (mounted) {
                      setState(() {
                        _isProgress = true;
                      });
                    }
                    Object? targetPath;

                    if (Platform.isIOS) {
                      var target = await getApplicationDocumentsDirectory();
                      targetPath = target.path.toString();
                    } else {
                      targetPath = '/storage/emulated/0/Download';
                      if (!await Directory(targetPath.toString()).exists()) {
                        targetPath = await getExternalStorageDirectory();
                      }
                    }

                    var targetFileName = 'Invoice_${widget.model!.id}';
                    var generatedPdfFile, filePath;
                    try {
                      generatedPdfFile =
                          await FlutterHtmlToPdf.convertFromHtmlContent(
                              response['data'],
                              targetPath.toString(),
                              targetFileName);
                      filePath = generatedPdfFile.path;

                      File fileDef = File(filePath);
                      await fileDef.create(recursive: true);
                      Uint8List bytes = await generatedPdfFile.readAsBytes();
                      await fileDef.writeAsBytes(bytes);
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          _isProgress = false;
                        });
                        setSnackbar(
                            getTranslated(context, 'somethingMSg')!, context);
                      }
                      return;
                    }

                    if (mounted) {
                      setState(() {
                        _isProgress = false;
                      });
                    }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                        "${getTranslated(context, 'INVOICE_PATH')} $targetFileName",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.black),
                      ),
                      action: SnackBarAction(
                          label: getTranslated(context, 'VIEW')!,
                          textColor: Theme.of(context).colorScheme.fontColor,
                          onPressed: () async {
                            await OpenFilex.open(filePath);
                          }),
                      backgroundColor: Theme.of(context).colorScheme.white,
                      elevation: 1.0,
                    ));
                  } else {
                    setSnackbar(
                        getTranslated(context, "PERMISSION_NOT_ALLOWED")!,
                        context);
                  }
                }),
          )
        : const SizedBox.shrink();
  }

/*  DwnInvoice() async {
    return widget.model!.invoice != ""
        ? Card(
        elevation: 0,
        child: InkWell(
            child: ListTile(
              dense: true,
              trailing: const Icon(
                Icons.keyboard_arrow_right,
                color: colors.primary,
              ),
              leading: const Icon(
                Icons.receipt,
                color: colors.primary,
              ),
              title: Text(
                getTranslated(context, 'DWNLD_INVOICE')!,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall!
                    .copyWith(color: Theme.of(context).colorScheme.lightBlack),
              ),
            ),
            onTap: () async {
              final status = await Permission.storage.request();
              bool permissionGranted = status == PermissionStatus.granted;

              if (permissionGranted) {
                try {
                  setState(() {
                    _isProgress = true;
                  });

                  var targetPath = Platform.isAndroid
                      ? await ExternalPath.getExternalStoragePublicDirectory(
                          ExternalPath.DIRECTORY_DOWNLOADS)
                      : (await getApplicationDocumentsDirectory()).path;

                  var targetFileName = 'Invoice_${widget.model!.id}';
                  var generatedPdfFile, filePath;

                  try {
                    generatedPdfFile =
                        await FlutterHtmlToPdf.convertFromHtmlContent(
                      widget.model!.invoice!,
                      targetPath.toString(),
                      targetFileName,
                    );
                    filePath = generatedPdfFile.path;

                    File fileDef = File(filePath);
                    await fileDef.create(recursive: true);
                    Uint8List bytes = await generatedPdfFile.readAsBytes();
                    await fileDef.writeAsBytes(bytes);
                  } catch (e) {
                    setState(() {
                      _isProgress = false;
                    });
                    setSnackbar(
                        getTranslated(context, 'somethingMSg')!, context);
                    return;
                  }

                  setState(() {
                    _isProgress = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                      "${getTranslated(context, 'INVOICE_PATH')} $targetFileName",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.black,
                      ),
                    ),
                    action: SnackBarAction(
                      label: getTranslated(context, 'VIEW')!,
                      textColor: Theme.of(context).colorScheme.fontColor,
                      onPressed: () async {
                        await OpenFilex.open(filePath);
                      },
                    ),
                    backgroundColor: Theme.of(context).colorScheme.white,
                    elevation: 1.0,
                  ));
                } catch (_) {
                  // Handle any exceptions here
                }
              }
            })):SizedBox.shrink();
  }*/

  downloadProductFile(
      BuildContext context, String orderItemID, OrderItem orderItem) {
    if (orderItem.listStatus!.contains(DELIVERD) &&
        orderItem.downloadAllowed == '1' &&
        orderItem.isDownload == "0") {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                getDownloadLink(
                  orderItemID,
                );
              },
              icon: const Icon(Icons.download, color: colors.primary),
              label: Text(
                getTranslated(context, 'DWN_LBL')!,
                style: const TextStyle(color: colors.primary),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).colorScheme.btnColor),
              ),
            ),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  downloadLinkFile(String orderItemId) async {
    if (currentLinkForDownload != '') {
      print("inner link");
      final status = await Permission.storage.request();

      if (status == PermissionStatus.granted) {
        if (mounted) {
          setState(() {
            _isProgress = true;
          });
        }
        String? filePath;

        if (Platform.isIOS) {
          var target = await getApplicationDocumentsDirectory();
          filePath = target.path.toString();
        } else {
          final externalDirectory = await getExternalStorageDirectory();
          var dir =
              await Directory('${externalDirectory!.path}/Download').create();

          filePath = dir.path;
        }

        var fileName = currentLinkForDownload
            .substring(currentLinkForDownload.lastIndexOf('/') + 1);
        File file = File('$filePath/$fileName');
        bool hasExisted = await file.exists();
        if (hasExisted) {
          final openFile = await OpenFilex.open('$filePath/$fileName');
        }
        setSnackbar(getTranslated(context, 'Downloading')!, context);
        print("filePath : $filePath");
        final taskid = await FlutterDownloader.enqueue(
          url: currentLinkForDownload,
          savedDir: filePath,
          headers: {'auth': 'test_for_sql_encoding'},
          showNotification: true,
          openFileFromNotification: true,
        ).onError((error, stackTrace) {
          if (mounted) {
            setState(() {
              _isProgress = false;
            });
          }
          setSnackbar('Error : $error', context);
          return null;
        }).catchError((error, stackTrace) {
          if (mounted) {
            setState(() {
              _isProgress = false;
            });
          }
        }).whenComplete(() {
          if (mounted) {
            setState(() {
              _isProgress = false;
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                getTranslated(context, 'OPEN_DWN_FILE_LBL')!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.black),
              ),
              action: SnackBarAction(
                label: getTranslated(context, 'VIEW')!,
                textColor: Theme.of(context).colorScheme.fontColor,
                onPressed: () async {
                  await OpenFilex.open(filePath);
                },
              ),
              backgroundColor: Theme.of(context).colorScheme.white,
              elevation: 1.0,
            ),
          );
          cancelOrder('delivered', updateOrderItemApi, orderItemId);
        });

        if (mounted) {
          setState(() {
            _isProgress = false;
          });
        }
      }
    } else {
      setSnackbar('something wrong file is not available yet .', context);
    }
  }

  Future getDownloadLink(String orderItemId) async {
    try {
      if (mounted) {
        setState(() {
          _isProgress = true;
        });
      }

      var parameter = {
        'order_item_id': orderItemId,
        USER_ID: context.read<UserProvider>().userId
      };

      currentLinkForDownload = '';

      apiBaseHelper.postAPICall(downloadLinkHashApi, parameter).then(
          (getdata) async {
        bool error = getdata['error'];

        if (!error) {
          if (getdata['data'] != []) {
            print("inner error false");
            setState(() {
              currentLinkForDownload = getdata['data'];
            });
            print("current link****$currentLinkForDownload");
            downloadLinkFile(orderItemId);
          }
        } else {
          setSnackbar(getdata['message'], context);
        }
        _isReturnClick = true;
        if (mounted) {
          setState(() {
            _isProgress = false;
          });
        }
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      });
    } catch (e) {
      setSnackbar(getTranslated(context, 'somethingMSg')!, context);
    }
  }

  Future<void> sendBankProof() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        if (mounted) {
          setState(() {
            _isProgress = true;
          });
        }

        var request = http.MultipartRequest("POST", setBankProofApi);
        request.headers.addAll(headers);
        request.fields[ORDER_ID] = widget.model!.id!;

        if (files.isNotEmpty) {
          for (var i = 0; i < files.length; i++) {
            final mimeType = lookupMimeType(files[i].path);

            var extension = mimeType!.split("/");

            var pic = await http.MultipartFile.fromPath(
              ATTACH,
              files[i].path,
              contentType: MediaType('image', extension[1]),
            );

            request.files.add(pic);
          }
        }

        var response = await request.send();
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);
        var getdata = json.decode(responseString);
        bool? error = getdata["error"];
        String msg = getdata['message'];

        files.clear();
        if (mounted) {
          setState(() {
            _isProgress = false;
          });
        }
        setSnackbar(msg, context);
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else if (mounted) {
      setState(() {
        _isNetworkAvail = false;
      });
    }
  }

  Widget getSubHeadingsTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: TabBar(
        controller: _tabController,
        tabs: [
          getTab(getTranslated(context, "ALL_DETAILS")!),
          getTab(getTranslated(context, "PROCESSING")!),
          getTab(getTranslated(context, "SHIPPED_LBL")!),
          getTab(widget.model!.isLocalPickUp != "1"
              ? getTranslated(context, "DELIVERED")!
              : getTranslated(context, 'PICKED_UP_LBL')!),
          getTab(getTranslated(context, "CANCELLED")!),
          getTab(getTranslated(context, "RETURNED")!),
        ],
        indicator: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(50),
          color: colors.primary,
        ),
        isScrollable: true,
        unselectedLabelColor: Theme.of(context).colorScheme.black,
        labelColor: Theme.of(context).colorScheme.white,
        automaticIndicatorColorAdjustment: true,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 1.0),
      ),
    );
  }

  reOrderDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext cxt) {
        return AlertDialog(
          title: Text(
            getTranslated(cxt, 'RE_ORDER')!,
            style: TextStyle(color: Theme.of(cxt).colorScheme.fontColor),
          ),
          content: Text(
            getTranslated(cxt, 'RE_ORDER_WARNNING')!,
            style: TextStyle(
              color: Theme.of(cxt).colorScheme.fontColor,
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                getTranslated(cxt, 'YES')!,
                style: const TextStyle(color: colors.primary),
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
            TextButton(
              child: Text(
                getTranslated(cxt, 'NO')!,
                style: const TextStyle(color: colors.primary),
              ),
              onPressed: () {
                Navigator.pop(context, false);
              },
            )
          ],
        );
      },
    ).then((value) {
      return value;
    });
  }

  bool loading = false;
  getOrderDetails(OrderModel model) {
    return Stack(
      children: [
        SingleChildScrollView(
          controller: controller,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                getOrderNoAndOTPDetails(model),
                model.delDate != null && model.delDate!.isNotEmpty
                    ? Card(
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            "${getTranslated(context, 'PREFER_DATE_TIME')!}: ${model.delDate!} - ${model.delTime!}",
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall!
                                .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .lightBlack2),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                getTracking(model),
                showNote(model),
                orderPrescriptionAttachments(model),
                bankTransfer(model),
                getSingleProduct(model, ''),
                downloadInvoice(),
                Card(
                  elevation: 0,
                  child: InkWell(
                      child: ListTile(
                        dense: true,
                        trailing: const Icon(
                          Icons.keyboard_arrow_right,
                          color: colors.primary,
                        ),
                        leading: const Icon(
                          Icons.shopping_cart,
                          color: colors.primary,
                        ),
                        title: Text(
                          getTranslated(context, 'RE_ORDER')!,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall!
                              .copyWith(
                                  color:
                                      Theme.of(context).colorScheme.lightBlack),
                        ),
                      ),
                      onTap: () async {
                        bool? didReOrder = await reOrderDialog(context);
                        if (didReOrder != null && didReOrder) {
                          setState(
                            () {
                              loading = true;
                            },
                          );
                          bool showSuccessMessage = false;
                          bool navigateToCartScreen = false;
                          try {
                            bool isNetworkAvail = await isNetworkAvailable();
                            if (isNetworkAvail) {
                              if (context.read<UserProvider>().userId != '') {
                                try {
                                  if (context.mounted) {
                                    setState(
                                      () {
                                        context
                                            .read<CartProvider>()
                                            .setProgress(true);
                                      },
                                    );
                                  }
                                  for (int i = 0;
                                      i < model.itemList!.length;
                                      i++) {
                                    final thisItem = model.itemList![i];
                                    var parameter = {
                                      USER_ID:
                                          context.read<UserProvider>().userId,
                                      PRODUCT_VARIENT_ID: thisItem.varientId,
                                      QTY: thisItem.qty,
                                    };

                                    await ApiBaseHelper()
                                        .postAPICall(manageCartApi, parameter)
                                        .then(
                                      (getdata) {
                                        bool error = getdata['error'];
                                        String? msg = getdata['message'];

                                        if (msg ==
                                            getTranslated(context,
                                                'Only single seller items are allow in cart. You can remove privious item(s) and add this item.')) {}
                                        if (!error) {
                                          var data = getdata['data'];
                                          context
                                              .read<UserProvider>()
                                              .setCartCount(data['cart_count']);
                                          var cart = getdata['cart'];
                                          List<SectionModel> cartList = [];
                                          cartList = (cart as List)
                                              .map((cart) =>
                                                  SectionModel.fromCart(cart))
                                              .toList();

                                          context
                                              .read<CartProvider>()
                                              .setCartlist(cartList);
                                          cartTotalClear();
                                          navigateToCartScreen = true;
                                        } else {
                                          if (msg !=
                                              getTranslated(context,
                                                  'Only single seller items are allow in cart.You can remove privious item(s) and add this item.')) {
                                            setSnackbar(msg!, context);
                                          }
                                        }
                                        if (context.mounted) {
                                          setState(
                                            () {
                                              context
                                                  .read<CartProvider>()
                                                  .setProgress(false);
                                            },
                                          );
                                        }

                                        if (msg == 'Cart Updated !') {
                                          showSuccessMessage = true;
                                        }
                                      },
                                      onError: (error) {
                                        setSnackbar(error.toString(), context);
                                      },
                                    );
                                  }
                                } on TimeoutException catch (_) {
                                  setSnackbar(
                                      getTranslated(context, 'somethingMSg')!,
                                      context);
                                  if (context.mounted) {
                                    setState(
                                      () {
                                        context
                                            .read<CartProvider>()
                                            .setProgress(false);
                                      },
                                    );
                                  }
                                }
                              }
                            }
                          } catch (e, st) {
                            print("HERE ${e.toString()} ${st.toString()}");
                          }

                          setState(
                            () {
                              loading = false;
                            },
                          );
                          if (navigateToCartScreen) {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => const Cart(
                                  fromBottom: false,
                                ),
                              ),
                            );
                          }
                          if (showSuccessMessage) {
                            setSnackbar(
                                getTranslated(
                                    context, 'RE_ORDER_SUCCESSFULLY')!,
                                context);
                          }
                        }
                      }),
                ),
                pickUpTimeDetails(),
                sellerNotesDetails(),
                model.itemList![0].productType != 'digital_product'
                    ? shippingDetails()
                    : const SizedBox.shrink(),
                priceDetails(model),
              ],
            ),
          ),
        ),
        //reorder processing
        if (loading)
          Align(
            alignment: Alignment.center,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
      ],
    );
  }

  getSingleProduct(OrderModel model, String activeStatus) {
    var count = 0;
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: model.itemList!.length,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, i) {
        var orderItem = model.itemList![i];
        proId = orderItem.id;
        print("active:${orderItem.status}");
        print("active status1: $activeStatus");
        if (activeStatus != '') {
          if (orderItem.status == activeStatus) {
            return productItem(orderItem, model);
          }
          if ((/* orderItem.status == SHIPED || */
                  orderItem.status == PLACED ||
                      orderItem.status == READY_TO_PICKUP) &&
              activeStatus == PROCESSED) {
            return productItem(orderItem, model);
          }

          if ((orderItem.status == RETURN_REQ_PENDING ||
                  orderItem.status == RETURN_REQ_DECLINE ||
                  orderItem.status == RETURN_REQ_APPROVED) &&
              activeStatus == RETURNED) {
            return productItem(orderItem, model);
          }
        } else {
          return productItem(orderItem, model);
        }
        count++;
        if (count == model.itemList!.length) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: Center(child: Text(getTranslated(context, "noItem")!)),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

  void openBottomSheet(BuildContext context, OrderItem orderItem) {
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
                    bottomSheetHandle(),
                    rateTextLabel(),
                    ratingWidget(double.parse(orderItem.userReviewRating!)),
                    writeReviewLabel(),
                    writeReviewField(orderItem.userReviewComment!),
                    getImageField(),
                    sendReviewButton(orderItem),
                  ],
                ),
              ),
            ],
          );
        });
  }

  Widget bottomSheetHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: Theme.of(context).colorScheme.lightBlack),
        height: 5,
        width: MediaQuery.of(context).size.width * 0.3,
      ),
    );
  }

  Widget rateTextLabel() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: getHeading("PRODUCT_REVIEW"),
    );
  }

  Widget ratingWidget(double rating) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: RatingBar.builder(
        initialRating: rating,
        minRating: 1,
        direction: Axis.horizontal,
        allowHalfRating: false,
        itemCount: 5,
        itemSize: 32,
        itemPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
        itemBuilder: (context, _) => const Icon(
          Icons.star,
          color: colors.yellow,
        ),
        onRatingUpdate: (rating) {
          curRating = rating;
        },
      ),
    );
  }

  Widget writeReviewLabel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Text(
        getTranslated(context, 'REVIEW_OPINION')!,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
      ),
    );
  }

  Widget writeReviewField(String comment) {
    commentTextController.text = comment;
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
        child: TextField(
          controller: commentTextController,
          style: Theme.of(context).textTheme.titleSmall,
          keyboardType: TextInputType.multiline,
          maxLines: 5,
          decoration: InputDecoration(
            border: OutlineInputBorder(
                borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.lightBlack,
                    width: 1.0)),
            hintText: getTranslated(context, 'REVIEW_HINT_LBL'),
            hintStyle: Theme.of(context).textTheme.titleSmall!.copyWith(
                color:
                    Theme.of(context).colorScheme.lightBlack2.withOpacity(0.7)),
          ),
        ));
  }

  Widget getImageField() {
    return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
      return Container(
        padding:
            const EdgeInsetsDirectional.only(start: 20.0, end: 20.0, top: 5),
        height: 100,
        child: Row(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(50.0)),
                    child: IconButton(
                        icon: Icon(
                          Icons.camera_alt,
                          color: Theme.of(context).colorScheme.white,
                          size: 25.0,
                        ),
                        onPressed: () {
                          _reviewImgFromGallery(setModalState);
                        }),
                  ),
                  Text(
                    getTranslated(context, 'ADD_YOUR_PHOTOS')!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack,
                        fontSize: 11),
                  )
                ],
              ),
            ),
            Expanded(
                child: ListView.builder(
              shrinkWrap: true,
              itemCount: reviewPhotos.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, i) {
                return InkWell(
                  child: Stack(
                    alignment: AlignmentDirectional.topEnd,
                    children: [
                      Image.file(
                        reviewPhotos[i],
                        width: 100,
                        height: 100,
                      ),
                      Container(
                          color: Theme.of(context).colorScheme.black26,
                          child: const Icon(
                            Icons.clear,
                            size: 15,
                          ))
                    ],
                  ),
                  onTap: () {
                    if (mounted) {
                      setModalState(() {
                        reviewPhotos.removeAt(i);
                      });
                    }
                  },
                );
              },
            )),
          ],
        ),
      );
    });
  }

  void _reviewImgFromGallery(StateSetter setModalState) async {
    try {
      var result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        allowMultiple: true,
      );
      if (result != null) {
        reviewPhotos = result.paths.map((path) => File(path!)).toList();
        if (mounted) setModalState(() {});
      } else {
        // User canceled the picker
      }
    } catch (e) {
      setSnackbar(getTranslated(context, "PERMISSION_NOT_ALLOWED")!, context);
    }
  }

  Widget sendReviewButton(OrderItem orderItem) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
            child: MaterialButton(
              height: 45.0,
              textColor: Theme.of(context).colorScheme.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0)),
              onPressed: () {
                if (curRating != 0 ||
                    commentTextController.text != '' ||
                    (reviewPhotos.isNotEmpty)) {
                  Navigator.pop(context);
                  setRating(curRating, commentTextController.text, reviewPhotos,
                      orderItem.productId);
                } else {
                  Navigator.pop(context);
                  setSnackbar(getTranslated(context, 'REVIEW_W')!, context);
                }
              },
              color: colors.primary,
              child: Text(
                orderItem.userReviewRating != "0"
                    ? getTranslated(context, "UPDATE_REVIEW_LBL")!
                    : getTranslated(context, "SEND_REVIEW")!,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Text getHeading(
    String title,
  ) {
    return Text(
      getTranslated(context, title)!,
      style: Theme.of(context).textTheme.titleLarge!.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.fontColor),
    );
  }

  Future<void> setRating(
      double rating, String comment, List<File> files, var productID) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var request = http.MultipartRequest("POST", setRatingApi);
        request.headers.addAll(headers);
        request.fields[USER_ID] = context.read<UserProvider>().userId;
        request.fields[PRODUCT_ID] = productID;

        if (files.isNotEmpty) {
          for (var i = 0; i < files.length; i++) {
            final mimeType = lookupMimeType(files[i].path);

            var extension = mimeType!.split("/");

            var pic = await http.MultipartFile.fromPath(
              IMGS,
              files[i].path,
              contentType: MediaType('image', extension[1]),
            );

            request.files.add(pic);
          }
        }

        if (comment != "") request.fields[COMMENT] = comment;
        if (rating != 0) request.fields[RATING] = rating.toString();
        var response = await request.send();
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);
        var getdata = json.decode(responseString);
        bool error = getdata["error"];
        String? msg = getdata['message'];

        if (!error) {
          setSnackbar(msg!, context);
        } else {
          setSnackbar(msg!, context);
        }
        commentTextController.text = "";
        files.clear();
        reviewPhotos.clear();
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else if (mounted) {
      setState(() {
        _isNetworkAvail = false;
      });
    }
  }

  Widget getOrderNoAndOTPDetails(OrderModel model) {
    return Card(
      elevation: 0.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${getTranslated(context, "ORDER_ID_LBL")!} - ${model.id}",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack2),
                ),
                Text(
                  "${model.dateTime}",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.lightBlack2),
                )
              ],
            ),
            model.otp != null && model.otp!.isNotEmpty && model.otp != "0"
                ? Text(
                    "${getTranslated(context, "OTP")!} - ${model.otp}",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.lightBlack2),
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  getTab(String title) {
    return Container(
      padding: const EdgeInsets.all(5.0),
      height: 35,
      child: Center(
        child: Text(title),
      ),
    );
  }

  getTracking(OrderModel model) {
    return model.tracking_id! != ""
        ? Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        model.courier_agency! != ""
                            ? Text(
                                "${getTranslated(context, 'COURIER_AGENCY')!}: ",
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.lightBlack2,
                                ),
                              )
                            : const SizedBox.shrink(),
                        model.tracking_id! != ""
                            ? Text(
                                "${getTranslated(context, 'TRACKING_ID')!}: ",
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.lightBlack2,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        model.courier_agency! != ""
                            ? Text(
                                model.courier_agency!,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.lightBlack2,
                                ),
                              )
                            : const SizedBox.shrink(),
                        model.tracking_id! != ""
                            ? RichText(
                                text: TextSpan(children: [
                                TextSpan(
                                  text: "",
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .lightBlack,
                                      fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                    text: model.courier_agency!,
                                    style: const TextStyle(
                                        color: colors.primary,
                                        decoration: TextDecoration.underline),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () async {
                                        var url = "${model.tracking_url}";

                                        if (await canLaunchUrlString(url)) {
                                          await launchUrlString(url);
                                        } else {
                                          setSnackbar(
                                              getTranslated(
                                                  context, 'URL_ERROR')!,
                                              context);
                                        }
                                      })
                              ]))
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  bankTransfer(OrderModel model) {
    return model.payMethod == "Bank Transfer"
        ? Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        getTranslated(context, 'BANKRECEIPT')!,
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack),
                      ),
                      SizedBox(
                        height: 30,
                        child: IconButton(
                            icon: const Icon(
                              Icons.add_photo_alternate,
                              color: colors.primary,
                              size: 20.0,
                            ),
                            onPressed: () {
                              _imgFromGallery();
                            }),
                      ),
                    ],
                  ),
                  model.attachList!.isNotEmpty
                      ? bankProof(model)
                      : const SizedBox.shrink(),
                  Container(
                    padding: const EdgeInsetsDirectional.only(
                        start: 20.0, end: 20.0, top: 5),
                    height: files.isNotEmpty ? 180 : 0,
                    child: Row(
                      children: [
                        Expanded(
                            child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: files.length,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, i) {
                            return InkWell(
                              child: Stack(
                                alignment: AlignmentDirectional.topEnd,
                                children: [
                                  Image.file(
                                    files[i],
                                    width: 180,
                                    height: 180,
                                  ),
                                  Container(
                                      color:
                                          Theme.of(context).colorScheme.black26,
                                      child: const Icon(
                                        Icons.clear,
                                        size: 15,
                                      ))
                                ],
                              ),
                              onTap: () {
                                if (mounted) {
                                  setState(() {
                                    files.removeAt(i);
                                  });
                                }
                              },
                            );
                          },
                        )),
                        InkWell(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.lightWhite,
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(4.0))),
                            child: Text(
                              getTranslated(context, 'SUBMIT_LBL')!,
                              style: TextStyle(
                                  color: _isProgress
                                      ? Theme.of(context)
                                          .colorScheme
                                          .fontColor
                                          .withOpacity(0.4)
                                      : Theme.of(context)
                                          .colorScheme
                                          .fontColor),
                            ),
                          ),
                          onTap: () {
                            if (!_isProgress) {
                              sendBankProof();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  orderPrescriptionAttachments(OrderModel model) {
    return model.orderPrescriptionAttachments!.isNotEmpty
        ? Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    getTranslated(context, 'PRESCRIPTION_ATTACHMENTS')!,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: Theme.of(context).colorScheme.lightBlack),
                  ),
                  model.orderPrescriptionAttachments!.isNotEmpty
                      ? prescriptionAttachments(model)
                      : const SizedBox.shrink(),
                ],
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  showNote(OrderModel model) {
    return model.note! != ""
        ? SizedBox(
            width: MediaQuery.of(context).size.width,
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${getTranslated(context, 'NOTE')}:",
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack2)),
                    Text(model.note!,
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack2)),
                  ],
                ),
              ),
            ),
          )
        : const SizedBox();
  }
}
