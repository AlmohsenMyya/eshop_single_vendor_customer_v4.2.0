import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:eshop/Helper/Color.dart';
import 'package:eshop/Helper/String.dart';
import 'package:eshop/Provider/CartProvider.dart';
import 'package:eshop/Provider/SettingProvider.dart';
import 'package:eshop/Provider/UserProvider.dart';
import 'package:eshop/app/routes.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
// Import for iOS features.
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/cart_var.dart';
import '../Model/Section_Model.dart';
import '../ui/styles/DesignConfig.dart';
import 'HomePage.dart';

class InstamojoWebview extends StatefulWidget {
  final String? url, from, msg, amt, orderId;
  final Function? updateWallet;

  const InstamojoWebview(
      {Key? key,
      this.url,
      this.from,
      this.msg,
      this.amt,
      this.orderId,
      this.updateWallet})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StatePayPalWebview();
  }
}

class StatePayPalWebview extends State<InstamojoWebview> {
  String message = "";
  bool isloading = true;
  late final WebViewController _controller;
  String currentStatus = '';
  String transactionId = '';
  DateTime? currentBackPressTime;
  late UserProvider userProvider;
  List<String> visitedUrls = [];

  @override
  void initState() {
    // TODO: implement initState
    webViewInitiliased();
    super.initState();
  }

  webViewInitiliased() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);
    // #enddocregion platform_features

    controller
      ..loadRequest(Uri.parse(widget.url!))
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('Toaster', onMessageReceived: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message.message)),
        );
      })
      ..setNavigationDelegate(NavigationDelegate(onPageFinished: (String url) {
        visitedUrls.add(url);
        print('******URL*****$url');
        if (url.contains('https://test.instamojo.com/order/status/') ||
            url.contains('https://instamojo.com/order/status/')) {
          print('finish inner url');
          print('currentstatus: $currentStatus****$transactionId');

          if (currentStatus != '' && transactionId != '') {
            print('inner status if');
            if (currentStatus == 'AUTHENTICATION_FAILED' ||
                currentStatus == 'AUTHORIZATION_FAILED') {
              deleteOrder();
              Timer(const Duration(seconds: 2), () {
                Navigator.pop(context);
              });
            } else if (currentStatus == 'CHARGED' &&
                visitedUrls.contains(url)) {
              if (widget.from == 'order') {
                print('inner');
                AddTransaction(transactionId, widget.orderId!, SUCCESS,
                    'Order placed successfully', true);
                userProvider.setCartCount('0');
                Timer(const Duration(seconds: 2), () {
                  // Navigator.pushAndRemoveUntil(
                  //   context,
                  //   CupertinoPageRoute(
                  //       builder: (BuildContext context) =>
                  //           const OrderSuccess()),
                  //   (final Route route) => route.isFirst,
                  // );
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    Routers.orderSuccessScreen,
                    (route) => route.isFirst,
                  );
                });
              } else if (widget.from == 'wallet') {
                widget.updateWallet!();
                Timer(const Duration(seconds: 2), () {
                  Navigator.pop(context);
                });
              }
            } else if (currentStatus == 'PENDING_VBV') {
              Timer(const Duration(seconds: 2), () {
                Navigator.pop(context);
              });
            }
          }
          // Redirect to a new screen
        }
        setState(() {
          isloading = false;
        });
      }, onNavigationRequest: (request) async {
        String responseurl = request.url;

        List<String> testdata = responseurl.split('?');

        for (String data in testdata) {
          if (data.split('=')[0].toLowerCase() == 'order_id') {
            setState(() {
              transactionId = data.split('=')[1];
            });

            break;
          }
        }

        if (responseurl.contains('AUTHENTICATION_FAILED') ||
            responseurl.contains('AUTHORIZATION_FAILED')) {
          if (responseurl.contains('AUTHENTICATION_FAILED')) {
            setState(() {
              currentStatus = 'AUTHENTICATION_FAILED';
            });
          } else {
            setState(() {
              currentStatus = 'AUTHORIZATION_FAILED';
              isloading = false;
            });
          }
        } else if (responseurl.contains('CHARGED')) {
          setState(() {
            currentStatus = 'CHARGED';
          });
        }
        if (responseurl.contains('PENDING_VBV')) {
          setState(() {
            currentStatus = 'PENDING_VBV';
          });
        }

        print('ourside prevent');

        if (currentStatus != '' && transactionId != '') {
          print('inner condition');
        }
        return NavigationDecision.navigate;
      }

          /*onNavigationRequest: (request) async {
          String responseurl = request.url;
          List<String> testdata = responseurl.split('?');
          print('******request url ******${request.url}');
                  if(request.url.contains('https://cde-staging.instamojo.com/juspay/return/')) {
                    if (mounted) {
                      setState(() {
                        isloading = true;
                        print('********mounted***********');
                      });
                    }

                    String responseurl = request.url;
                    print('response url ****');
                    print(responseurl);

                    if (responseurl.contains("AUTHENTICATION_FAILED") ||
                        responseurl.contains("AUTHORIZATION_FAILED")) {
                      print('********faileddddd***********');
                      if (mounted) {
                        setState(() {
                          isloading = false;
                          message = "Transaction Failed";
                          print('********txxxxx failed***********');
                        });
                      }
                      Timer(const Duration(seconds: 1), () {
                        Navigator.pop(context);
                      });
                    } else if (responseurl.contains("CHARGED")) {
                      print('*******chargedd***********');
                      if (mounted) {
                        setState(() {
                          if (mounted) {
                            setState(() {
                              print('********successsss***********');
                              message = "Transaction Successfull";
                            });
                          }
                        });
                      }
                      List<String> testdata = responseurl.split("?");
                      print('testdata****');
                      print(testdata);
                      for (String data in testdata) {
                        if (
                            data.split("=")[0].toLowerCase() ==
                                "order_id") {
                          print('inside testdata ') ;
                          userProvider.setCartCount("0");

                          if (widget.from == "order") {
                            print('inner');
                            Navigator.pushAndRemoveUntil(
                                context,
                                CupertinoPageRoute(
                                    builder: (BuildContext context) =>
                                    const OrderSuccess()),
                                (final Route route) => route.isFirst,);

                            String txid = data.split("=")[1];
                            print('txid $txid ******** ${data.split("=")[0]}');
                            AddTransaction(txid, widget.orderId!, SUCCESS,
                                'Order placed successfully', true);
                          } else if(widget.from == "wallet"
                          ){
                            Timer(const Duration(seconds: 1), () {
                              Navigator.pop(context);

                            });
                            widget.updateWallet!();
                            */ /*else if () {
                            if (request.url.startsWith(FLUTTERWAVE_RES_URL)) {
                              String txid = data.split("=")[1];
                              setSnackbar('Transaction Successful', context);
                              if (mounted) {
                                setState(() {
                                  isloading = false;
                                });
                              }
                              Timer(const Duration(seconds: 1), () {
                                Navigator.pop(context);
                              });

                              //sendRequest(txid, "flutterwave");
                            } else {
                              Navigator.of(context).pop();
                            }
                          }*/ /*
                          }

                          break;
                        }
                      }
                    }
                    if (responseurl.contains("PENDING_VBV")) {
                      if (mounted) {
                        setState(() {
                          if (mounted) {
                            setState(() {
                              message = "Transaction Pending";
                            });
                          }
                        });
                      }
                      Navigator.pop(context);
                    }

                    if (request.url.startsWith(PAYPAL_RESPONSE_URL) &&
                        widget.orderId != null &&
                        (responseurl.contains('Canceled-Reversal') ||
                            responseurl.contains('Denied') ||
                            responseurl.contains('Failed'))) {
                      deleteOrder();
                    }
                    return NavigationDecision.prevent;
                  }
          return NavigationDecision.navigate;
        },*/

          ));

    // #docregion platform_features
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
    // #enddocregion platform_features

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
        //  key: scaffoldKey,
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          titleSpacing: 0,
          leading: Builder(builder: (BuildContext context) {
            return Container(
              margin: const EdgeInsets.all(10),
              child: Card(
                elevation: 0,
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () {
                    DateTime now = DateTime.now();
                    if (currentBackPressTime == null ||
                        now.difference(currentBackPressTime!) >
                            const Duration(seconds: 2)) {
                      currentBackPressTime = now;
                      setSnackbar(
                          "Don't press back while doing payment!\n ${getTranslated(context, 'EXIT_WR')!}",
                          context);
                    }
                    if (widget.from == "order" && widget.orderId != null) {
                      deleteOrder();
                    }
                    Navigator.pop(context);
                  },
                  child: const Center(
                    child: Icon(
                      Icons.keyboard_arrow_left,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
            );
          }),
          title: Text(
            appName,
            style: TextStyle(
              color: Theme.of(context).colorScheme.fontColor,
            ),
          ),
        ),
        body: PopScope(
            canPop: false,
            onPopInvoked: (didPop) {
              DateTime now = DateTime.now();
              if (currentBackPressTime == null ||
                  now.difference(currentBackPressTime!) >
                      const Duration(seconds: 2)) {
                currentBackPressTime = now;
                setSnackbar(
                    "Don't press back while doing payment!\n ${getTranslated(context, 'EXIT_WR')!}",
                    context);
              } else {
                if (widget.from == "order" && widget.orderId != null) {
                  deleteOrder();
                }
                if (didPop) {
                  return;
                }
                Navigator.pop(context, 'true');
              }
            },
            child: Stack(
              children: <Widget>[
                WebViewWidget(controller: _controller),
                isloading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: colors.primary,
                        ),
                      )
                    : const SizedBox(),
                message.trim().isEmpty
                    ? const SizedBox.shrink()
                    : Center(
                        child: Container(
                            color: colors.primary,
                            padding: const EdgeInsets.all(5),
                            margin: const EdgeInsets.all(5),
                            child: Text(
                              message,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.white),
                            )))
              ],
            )));
  }

  Future<void> sendRequest(String txnId, String payMethod) async {
    String orderId =
        "wallet-refill-user-${context.read<UserProvider>().userId}-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(900) + 100}";
    try {
      var parameter = {
        USER_ID: context.read<UserProvider>().userId,
        AMOUNT: widget.amt,
        TRANS_TYPE: WALLET,
        TYPE: CREDIT,
        MSG: (widget.msg == '' || widget.msg!.isEmpty)
            ? "Added through wallet"
            : widget.msg,
        TXNID: txnId,
        ORDER_ID: orderId,
        STATUS: "Success",
        PAYMENT_METHOD: payMethod.toLowerCase()
      };

      apiBaseHelper.postAPICall(addTransactionApi, parameter).then((getdata) {
        bool error = getdata["error"];

        if (!error) {
          UserProvider userProvider = Provider.of<UserProvider>(context);
          userProvider.setBalance(
              double.parse(getdata["new_balance"]).toStringAsFixed(2));
        }
        if (mounted) {
          setState(() {
            isloading = false;
          });
        }

        Navigator.of(context).pop();
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      });
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg')!, context);

      setState(() {
        isloading = false;
      });
    }
  }

  Future<void> deleteOrder() async {
    try {
      var parameter = {
        ORDER_ID: widget.orderId,
      };
      apiBaseHelper.postAPICall(deleteOrderApi, parameter).then((getdata) {
        if (mounted) {
          setState(() {
            isloading = false;
          });
        }

        Navigator.of(context).pop();
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      });
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg')!, context);

      setState(() {
        isloading = false;
      });
    }
  }

  /* JavascriptChannel _toasterJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'Toaster',
        onMessageReceived: (JavascriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        });
  }*/

  Future<void> placeOrder(String tranId) async {
    setState(() {
      isloading = true;
    });
    SettingProvider settingsProvider =
        Provider.of<SettingProvider>(context, listen: false);

    String? mob = await settingsProvider.getPrefrence(MOBILE);
    String? varientId, quantity;
    List<SectionModel> cartList = context.read<CartProvider>().cartList;

    for (SectionModel sec in cartList) {
      varientId =
          varientId != null ? "$varientId,${sec.varientId!}" : sec.varientId;
      quantity = quantity != null ? "$quantity,${sec.qty!}" : sec.qty;
    }
    String payVia;

    payVia = "Flutterwave";

    var request = http.MultipartRequest("POST", placeOrderApi);
    request.headers.addAll(headers);

    try {
      request.fields[USER_ID] = context.read<UserProvider>().userId;
      request.fields[MOBILE] = mob!;
      request.fields[PRODUCT_VARIENT_ID] = varientId!;
      request.fields[QUANTITY] = quantity!;
      request.fields[TOTAL] = oriPrice.toString();
      request.fields[DEL_CHARGE] = delCharge.toString();
      request.fields[TAX_PER] = taxPer.toString();
      request.fields[FINAL_TOTAL] = usedBal > 0
          ? totalPrice.toString()
          : isStorePickUp == "false"
              ? (totalPrice + delCharge).toString()
              : totalPrice.toString();
      request.fields[PAYMENT_METHOD] = payVia;
      request.fields[ISWALLETBALUSED] = isUseWallet! ? "1" : "0";
      request.fields[WALLET_BAL_USED] = usedBal.toString();

      if (IS_LOCAL_PICKUP == "1") {
        request.fields[LOCAL_PICKUP] = isStorePickUp == "true" ? "1" : "0";
      }

      if (IS_LOCAL_PICKUP != "1" || isStorePickUp != "true") {
        request.fields[ADD_ID] = selAddress!;
      }

      if (isTimeSlot!) {
        request.fields[DELIVERY_TIME] = selTime ?? 'Anytime';
        request.fields[DELIVERY_DATE] = selDate ?? '';
      }
      if (isPromoValid!) {
        request.fields[PROMOCODE] = promocode!;
        request.fields[PROMO_DIS] = promoAmt.toString();
      }

      if (prescriptionImages.isNotEmpty) {
        for (var i = 0; i < prescriptionImages.length; i++) {
          final mimeType = lookupMimeType(prescriptionImages[i].path);

          var extension = mimeType!.split("/");

          var pic = await http.MultipartFile.fromPath(
            DOCUMENT,
            prescriptionImages[i].path,
            contentType: MediaType('image', extension[1]),
          );

          request.files.add(pic);
        }
      }

      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);

      if (response.statusCode == 200) {
        var getdata = json.decode(responseString);

        bool error = getdata["error"];
        String? msg = getdata["message"];
        if (!error) {
          String orderId = getdata["order_id"].toString();

          AddTransaction(tranId, orderId, SUCCESS, msg, true);
        } else {
          setSnackbar(msg!, context);
        }
        if (mounted) {
          setState(() {
            isloading = false;
          });
        }
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        setState(() {
          isloading = false;
        });
      }
    }
  }

  Future<void> AddTransaction(String tranId, String orderID, String status,
      String? msg, bool redirect) async {
    try {
      var parameter = {
        USER_ID: context.read<UserProvider>().userId,
        ORDER_ID: orderID,
        TYPE: payMethod,
        TXNID: tranId,
        AMOUNT: usedBal > 0
            ? totalPrice.toString()
            : isStorePickUp == "false"
                ? (totalPrice + delCharge).toString()
                : totalPrice.toString(),
        STATUS: status,
        MSG: msg
      };

      apiBaseHelper.postAPICall(addTransactionApi, parameter).then((getdata) {
        DateTime now = DateTime.now();
        currentBackPressTime = now;

        bool error = getdata["error"];
        String? msg1 = getdata["message"];
        if (!error) {
          if (redirect) {
            userProvider.setCartCount("0");

            promoAmt = 0;
            remWalBal = 0;
            usedBal = 0;
            payMethod = '';
            isPromoValid = false;
            isUseWallet = false;
            isPayLayShow = true;
            selectedMethod = null;
            totalPrice = 0;
            oriPrice = 0;

            taxPer = 0;
            delCharge = 0;

            // Navigator.pushAndRemoveUntil(
            //   context,
            //   CupertinoPageRoute(
            //       builder: (BuildContext context) => const OrderSuccess()),
            //   (final Route route) => route.isFirst,
            // );

            Navigator.pushNamedAndRemoveUntil(
              context,
              Routers.orderSuccessScreen,
              (route) => route.isFirst,
            );
          }
        } else {
          setSnackbar(msg1!, context);
        }
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      });
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg')!, context);
    }
  }
}
