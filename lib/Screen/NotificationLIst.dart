import 'dart:async';

import 'package:eshop/Model/Notification_Model.dart';
import 'package:eshop/Model/Section_Model.dart';
import 'package:eshop/Screen/Chat.dart';
import 'package:eshop/Screen/Customer_Support.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import '../app/routes.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/widgets/AppBarWidget.dart';
import '../ui/widgets/AppBtn.dart';
import '../utils/blured_router.dart';
import 'HomePage.dart';

class NotificationList extends StatefulWidget {
  const NotificationList({Key? key}) : super(key: key);
  static route(RouteSettings settings) {
    return BlurredRouter(
      builder: (context) {
        return NotificationList();
      },
    );
  }

  @override
  State<StatefulWidget> createState() => StateNoti();
}

class StateNoti extends State<NotificationList> with TickerProviderStateMixin {
  ScrollController controller = ScrollController();
  List<NotificationModel> tempList = [];
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  List<NotificationModel> notiList = [];
  int offset = 0;
  int total = 0;
  bool isLoadingmore = true;
  bool _isLoading = true;

  @override
  void initState() {
    getNotification();
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
    super.initState();
  }

  @override
  void dispose() {
    buttonController!.dispose();
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
                getNotification();
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
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    offset = 0;
    total = 0;
    notiList.clear();
    return getNotification();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: getAppBar(getTranslated(context, 'NOTIFICATION')!, context),
        body: _isNetworkAvail
            ? _isLoading
                ? shimmer(context)
                : notiList.isEmpty
                    ? Padding(
                        padding: const EdgeInsetsDirectional.only(
                            top: kToolbarHeight),
                        child: Center(
                            child: Text(getTranslated(context, 'noNoti')!)))
                    : RefreshIndicator(
                        color: colors.primary,
                        key: _refreshIndicatorKey,
                        onRefresh: _refresh,
                        child: ListView.builder(
                          // shrinkWrap: true,
                          controller: controller,
                          itemCount: (offset < total)
                              ? notiList.length + 1
                              : notiList.length,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return (index == notiList.length && isLoadingmore)
                                ? singleItemSimmer(context)
                                : listItem(index);
                          },
                        ))
            : noInternet(context));
  }

  Widget listItem(int index) {
    NotificationModel model = notiList[index];

    return GestureDetector(
      onTap: () async {
        if (model.type == "products") {
          getProduct(model.typeId!, 0, 0, true);
        } else if (model.type == "categories") {
          Navigator.of(context).pop(true);
        } else if (model.type == "wallet") {
          Navigator.pushNamed(context, Routers.myWalletScreen);
        } else if (model.type == 'order') {
          // Navigator.push(context,
          //     (CupertinoPageRoute(builder: (context) => const MyOrder())));
          Navigator.pushNamed(context, Routers.myOrderScreen);
        } else if (model.type == "ticket_message") {
          Navigator.push(
            context,
            CupertinoPageRoute(
                builder: (context) => Chat(
                      id: model.id,
                      status: "",
                    )),
          );
        } else if (model.type == "ticket_status") {
          Navigator.push(
              context,
              CupertinoPageRoute(
                  builder: (context) => const CustomerSupport()));
        } else if (model.type == "notification_url") {
          String url = model.urlLink.toString();
          try {
            await launchUrl(Uri.parse(url),
                mode: LaunchMode.externalApplication);
            if (await canLaunchUrlString(url)) {
            } else {
              throw 'Could not launch $url';
            }
          } catch (e) {
            print("error ${e.toString()}");
          }
        } else {
          setSnackbar("It is a normal Notification", context);
        }
      },
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      model.date!,
                      style: const TextStyle(color: colors.primary),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        model.title!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(model.desc!)
                  ],
                ),
              ),
              model.img != "" && model.img != ''
                  ? InkWell(
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: Hero(
                          tag: "$index${model.id!}",
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(
                              model.img!,
                            ),
                            radius: 25,
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).push(PageRouteBuilder(
                            opaque: false,
                            barrierDismissible: true,
                            pageBuilder: (BuildContext context, _, __) {
                              return AlertDialog(
                                elevation: 0,
                                contentPadding: const EdgeInsets.all(0),
                                backgroundColor: Colors.transparent,
                                content: Hero(
                                    tag: "$index${model.id!}",
                                    child: networkImageCommon(
                                        model.img!, 150, false)
                                    /*CachedNetworkImage(
                                    imageUrl: model.img!,
                                    fadeInDuration:
                                        const Duration(milliseconds: 150),
                                    placeholder: (context, url) {
                                      return placeHolder(150);
                                    },
                                    errorWidget: (context, error, stackTrace) =>
                                        erroWidget(150),
                                  ),*/
                                    ),
                              );
                            }));

                        // return showDialog(
                        //     context: context,
                        //     builder: (BuildContext context) {
                        //       return StatefulBuilder(builder:
                        //           (BuildContext context, StateSetter setStater) {
                        //         return AlertDialog(
                        //             backgroundColor: Colors.transparent,
                        //             shape: RoundedRectangleBorder(
                        //                 borderRadius: BorderRadius.all(
                        //                     Radius.circular(5.0))),
                        //             content: Hero(
                        //               tag: model.id,
                        //               child: FadeInImage(
                        //                 image: CachedNetworkImageProvider(model.img),
                        //                 fadeInDuration:
                        //                     Duration(milliseconds: 150),
                        //                 placeholder: (context,url) {return placeHolder(150),
                        //               ),
                        //             ));
                        //       });
                        //     });
                      },
                    )
                  : Container(
                      height: 0,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> getNotification() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
        };

        apiBaseHelper.postAPICall(getNotificationApi, parameter).then(
            (getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];

          if (!error) {
            total = int.parse(getdata["total"]);

            if ((offset) < total) {
              tempList.clear();
              var data = getdata["data"];
              tempList = (data as List)
                  .map((data) => NotificationModel.fromJson(data))
                  .toList();

              notiList.addAll(tempList);

              offset = offset + perPage;
            }
          } else {
            if (msg != "Products Not Found !") setSnackbar(msg!, context);
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

            if (offset < total) getNotification();
          });
        }
      }
    }
  }

  Future<void> getProduct(String id, int index, int secPos, bool list) async {
    try {
      var parameter = {
        ID: id,
      };

      apiBaseHelper.postAPICall(getProductApi, parameter).then((getdata) {
        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          var data = getdata["data"];

          List<Product> items = [];

          items = (data as List).map((data) => Product.fromJson(data)).toList();
          currentHero = notifyHero;

          Navigator.pushNamed(context, Routers.productDetails, arguments: {
            "index": int.parse(id),
            "secPos": secPos,
            "list": list,
            "id": items[0].id!,
          });
        } else {}
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      });
    } on Exception {}
  }
}
