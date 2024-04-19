import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Helper/Color.dart';
import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import '../Model/Transaction_Model.dart';
import '../Provider/UserProvider.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/widgets/AppBarWidget.dart';
import '../ui/widgets/AppBtn.dart';
import '../utils/blured_router.dart';
import 'HomePage.dart';

class TransactionHistory extends StatefulWidget {
  const TransactionHistory({Key? key}) : super(key: key);
  static route(RouteSettings settings) {
    Map? arguments = settings.arguments as Map?;
    return BlurredRouter(
      builder: (context) {
        return TransactionHistory();
      },
    );
  }

  @override
  _TransactionHistoryState createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends State<TransactionHistory>
    with TickerProviderStateMixin {
  bool _isNetworkAvail = true;
  List<TransactionModel> tranList = [];
  int offset = 0;
  int total = 0;
  bool isLoadingmore = true;
  bool _isLoading = true;
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  ScrollController controller = ScrollController();
  List<TransactionModel> tempList = [];

  @override
  void initState() {
    getTransaction();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // key: _scaffoldKey,
        appBar: getAppBar(getTranslated(context, 'MYTRANSACTION')!, context),
        body: _isNetworkAvail
            ? _isLoading
                ? shimmer(context)
                : showContent()
            : noInternet(context));
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
                getTransaction();
              } else {
                await buttonController!.reverse();
                setState(() {});
              }
            });
          },
        )
      ]),
    );
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  Future<void> getTransaction() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          LIMIT: perPage.toString(),
          OFFSET: offset.toString(),
          USER_ID: context.read<UserProvider>().userId,
        };

        apiBaseHelper.postAPICall(getWalTranApi, parameter).then((getdata) {
          bool error = getdata["error"];

          if (!error) {
            total = int.parse(getdata["total"]);

            if ((offset) < total) {
              tempList.clear();
              var data = getdata["data"];
              tempList = (data as List)
                  .map((data) => TransactionModel.fromJson(data))
                  .toList();

              tranList.addAll(tempList);

              offset = offset + perPage;
            }
          } else {
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

        setState(() {
          _isLoading = false;
          isLoadingmore = false;
        });
      }
    } else {
      setState(() {
        _isNetworkAvail = false;
      });
    }

    return;
  }

  showContent() {
    return tranList.isEmpty
        ? getNoItem(context)
        : ListView.builder(
            shrinkWrap: true,
            controller: controller,
            itemCount: (offset < total) ? tranList.length + 1 : tranList.length,
            physics: const AlwaysScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return (index == tranList.length && isLoadingmore)
                  ? const Center(
                      child: CircularProgressIndicator(
                      color: colors.primary,
                    ))
                  : listItem(index);
            },
          );
  }

  listItem(int index) {
    Color back;
    if (tranList[index].status!.toLowerCase().contains("success")) {
      back = Colors.green;
    } else if (tranList[index].status!.toLowerCase().contains("failure")) {
      back = Colors.red;
    } else {
      back = Colors.orange;
    }
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(5.0),
      child: InkWell(
          borderRadius: BorderRadius.circular(4),
          child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            "${getTranslated(context, 'AMOUNT')!} : ${getPriceFormat(context, double.parse(tranList[index].amt!))!}",
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.fontColor,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(tranList[index].date!),
                      ],
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                                "${getTranslated(context, 'ORDER_ID_LBL')!} : ${tranList[index].orderId!}"),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                                color: back,
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(4.0))),
                            child: Text(
                              tranList[index].status!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.white),
                            ),
                          )
                        ],
                      ),
                    ),
                    tranList[index].type != null &&
                            tranList[index].type!.isNotEmpty
                        ? Text(
                            "${getTranslated(context, 'PAYMENT_METHOD_LBL')!} : ${tranList[index].type!}")
                        : const SizedBox.shrink(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: tranList[index].msg != null &&
                              tranList[index].msg!.isNotEmpty
                          ? Text(
                              "${getTranslated(context, 'MSG')!} : ${tranList[index].msg!}")
                          : const SizedBox.shrink(),
                    ),
                    tranList[index].txnID != null &&
                            tranList[index].txnID!.isNotEmpty
                        ? Text(
                            "${getTranslated(context, 'Txn_id')!} : ${tranList[index].txnID!}")
                        : const SizedBox.shrink(),
                  ]))),
    );
  }

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (mounted) {
        if (mounted) {
          setState(() {
            isLoadingmore = true;

            if (offset < total) getTransaction();
          });
        }
      }
    }
  }
}
