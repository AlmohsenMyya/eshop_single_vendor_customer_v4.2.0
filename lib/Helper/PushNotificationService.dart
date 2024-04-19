import 'dart:convert';
import 'dart:io';

import 'package:eshop/Helper/routes.dart';
import 'package:eshop/Model/message.dart' as msg;
import 'package:eshop/Model/personalChatHistory.dart';
import 'package:eshop/Provider/SettingProvider.dart';
import 'package:eshop/Provider/pushNotificationProvider.dart';
import 'package:eshop/Screen/Dashboard.dart';
import 'package:eshop/cubits/personalConverstationsCubit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Model/FlashSaleModel.dart';
import '../Provider/FlashSaleProvider.dart';
import '../Screen/All_Category.dart';
import '../Screen/Chat.dart';
import '../Screen/Customer_Support.dart';
import '../Screen/FlashSaleProductList.dart';
import '../Screen/HomePage.dart';
import '../Screen/Splash.dart';
import '../app/routes.dart';
import '../main.dart';
import '../ui/styles/DesignConfig.dart';
import 'Constant.dart';
import 'Session.dart';
import 'String.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
FirebaseMessaging messaging = FirebaseMessaging.instance;

backgroundMessage(NotificationResponse notificationResponse) {
  print(
      'notification(${notificationResponse.id}) action tapped: ${notificationResponse.actionId} with payload: ${notificationResponse.payload}');
  if (notificationResponse.input?.isNotEmpty ?? false) {
    print(
        'notification action tapped with input: ${notificationResponse.input}');
  }
}

class PushNotificationService {
  late BuildContext context;

  PushNotificationService({required this.context});

  setDeviceToken(
      {bool clearSesssionToken = false, SettingProvider? settingProvider}) {
    if (clearSesssionToken) {
      settingProvider ??= Provider.of<SettingProvider>(context, listen: false);
      settingProvider.setPrefrence(FCMTOKEN, '');
    }
    messaging.getToken().then(
      (token) async {
        context.read<PushNotificationProvider>().registerToken(token, context);
      },
    );
  }

  Future initialise() async {
    permission();

    setDeviceToken();
    FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('mipmap/notification');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification:
          (int id, String? title, String? body, String? payload) async {},
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) {
        print("notification response ${notificationResponse.payload}");
        switch (notificationResponse.notificationResponseType) {
          case NotificationResponseType.selectedNotification:
            selectNotificationPayload(notificationResponse.payload!);
            break;
          case NotificationResponseType.selectedNotificationAction:
            print(
                "notification-action-id--->${notificationResponse.actionId}==${notificationResponse.payload}");
            break;
        }
      },
      onDidReceiveBackgroundNotificationResponse: backgroundMessage,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      SettingProvider settingsProvider =
          Provider.of<SettingProvider>(context, listen: false);
      if (message.notification != null) {
        var data = message.notification!;
        var title = data.title.toString();
        var body = data.body.toString();
        var image = message.data['image'] ?? '';

        var type = message.data['type'] ?? '';
        var id = '';
        id = message.data['type_id'] ?? '';
        var urlLink = message.data['link'] ?? '';

        if (type == 'chat') {
          /*
              [{"id":"267","from_id":"2","to_id":"8","is_read":"1","message":"Geralt of rivia","type":"person","media":"","date_created":"2023-07-19 13:15:26","picture":"dikshita","senders_name":"dikshita","position":"right","media_files":"","text":"Geralt of rivia"}]
          */

          final messages = jsonDecode(message.data['message']) as List;

          String payload = '';

          if (messages.isNotEmpty) {
            payload = jsonEncode(messages.first);
          }

          if (converstationScreenStateKey.currentState?.mounted ?? false) {
            final state = converstationScreenStateKey.currentState!;
            if (state.widget.isGroup) {
              if (messages.isNotEmpty) {
                if (state.widget.groupDetails?.groupId !=
                    messages.first['to_id']) {
                  // context
                  //     .read<GroupConverstationsCubit>()
                  //     .markNewMessageArrivedInGroup(
                  //         groupId: messages.first['to_id'].toString());
                  // generateChatLocalNotification(
                  //     title: title, body: body, payload: payload);
                } else {
                  state.addMessage(
                      message: msg.Message.fromJson(messages.first));
                }
              }
            } else {
              if (messages.isNotEmpty) {
                if (state.widget.personalChatHistory?.getOtherUserId() !=
                    messages.first['from_id']) {
                  generateChatLocalNotification(
                      title: title, body: body, payload: payload);
                  context
                      .read<PersonalConverstationsCubit>()
                      .updateUnreadMessageCounter(
                        userId: messages.first['from_id'].toString(),
                      );
                } else {
                  state.addMessage(
                      message: msg.Message.fromJson(messages.first));
                }
              }
            }
          } else {
            //senders_name
            generateChatLocalNotification(
                title: title, body: body, payload: payload);

            //Update the unread message counter
            if (messages.isNotEmpty) {
              if (messages.first['type'] == 'person') {
                context
                    .read<PersonalConverstationsCubit>()
                    .updateUnreadMessageCounter(
                      userId: messages.first['from_id'].toString(),
                    );
              } else {}
            }
          }
        } else if (type == "ticket_status") {
          Navigator.push(
              context,
              CupertinoPageRoute(
                  builder: (context) => const CustomerSupport()));
        } else if (type == "ticket_message") {
          if (CUR_TICK_ID == id) {
            if (chatstreamdata != null) {
              var parsedJson = json.decode(message.data['chat']);
              parsedJson = parsedJson[0];

              Map<String, dynamic> sendata = {
                "id": parsedJson[ID],
                "title": parsedJson[TITLE],
                "message": parsedJson[MESSAGE],
                "user_id": parsedJson[USER_ID],
                "name": parsedJson[NAME],
                "date_created": parsedJson[DATE_CREATED],
                "attachments": parsedJson["attachments"]
              };
              var chat = {};

              chat["data"] = sendata;
              if (parsedJson[USER_ID] != settingsProvider.userId) {
                chatstreamdata!.sink.add(jsonEncode(chat));
              }
            }
          } else {
            if (image != null && image != 'null' && image != '') {
              generateImageNotication(title, body, image, type, id, urlLink);
            } else {
              generateSimpleNotication(title, body, type, id, urlLink);
            }
          }
        } else if (image != null && image != 'null' && image != '') {
          generateImageNotication(title, body, image, type, id, urlLink);
        } else {
          generateSimpleNotication(title, body, type, id, urlLink);
        }
      }
    });

    messaging.getInitialMessage().then((RemoteMessage? message) async {
      if (message != null) {
        print("message******${message.data.toString()}");
        bool back = await Provider.of<SettingProvider>(context, listen: false)
            .getPrefrenceBool(ISFROMBACK);

        if (back) {
          var type = message.data['type'] ?? '';
          var id = '';
          id = message.data['type_id'] ?? '';
          String urlLink = message.data['link'] ?? "";
          print("URL is $urlLink and type is $type");
          if (type == "products") {
            context.read<PushNotificationProvider>().getProduct(id, 0, 0, true);
          } else if (type == 'chat') {
            _onTapChatNotification(message: message);
          } else if (type == "categories") {
            Navigator.push(
                context,
                (CupertinoPageRoute(
                    builder: (context) => const AllCategory())));
          } else if (type == "wallet") {
            Navigator.pushNamed(context, Routers.myWalletScreen);
          } else if (type == 'order' || type == 'place_order') {
            // Navigator.push(context,
            //     (CupertinoPageRoute(builder: (context) => const MyOrder())));
            Navigator.pushNamed(context, Routers.myOrderScreen);
          } else if (type == "ticket_message") {
            Navigator.push(
              context,
              CupertinoPageRoute(
                  builder: (context) => Chat(
                        id: id,
                        status: "",
                      )),
            );
          } else if (type == "ticket_status") {
            Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (context) => const CustomerSupport()));
          } else if (type == "notification_url") {
            print("here we are");
            String url = urlLink.toString();
            try {
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url),
                    mode: LaunchMode.externalApplication);
              } else {
                throw 'Could not launch $url';
              }
            } catch (e) {
              throw 'Something went wrong';
            }
          } else if (type == "flash_sale") {
            getFlashSale(id);
          } else {
            Navigator.push(context,
                (CupertinoPageRoute(builder: (context) => const Splash())));
          }
          Provider.of<SettingProvider>(context, listen: false)
              .setPrefrenceBool(ISFROMBACK, false);
        }
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      print("message on opened app listen******${message.data.toString()}");
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var type = message.data['type'] ?? '';
      var id = '';
      String urlLink = '';
      try {
        id = message.data['type_id'] ?? '';
        urlLink = message.data['link'];
      } catch (_) {}

      if (type == "products") {
        context.read<PushNotificationProvider>().getProduct(id, 0, 0, true);
      } else if (type == 'chat') {
        _onTapChatNotification(message: message);
      } else if (type == "categories") {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (context) => const AllCategory()),
        );
      } else if (type == "wallet") {
        Navigator.pushNamed(context, Routers.myWalletScreen);
      } else if (type == 'order' || type == 'place_order') {
        // Navigator.push(context,
        //     (CupertinoPageRoute(builder: (context) => const MyOrder())));
        Navigator.pushNamed(context, Routers.myOrderScreen);
      } else if (type == "ticket_message") {
        Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) => Chat(
                    id: id,
                    status: "",
                  )),
        );
      } else if (type == "ticket_status") {
        Navigator.push(context,
            CupertinoPageRoute(builder: (context) => const CustomerSupport()));
      } else if (type == "notification_url") {
        String url = urlLink.toString();
        try {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url),
                mode: LaunchMode.externalApplication);
          } else {
            throw 'Could not launch $url';
          }
        } catch (e) {
          throw 'Something went wrong';
        }
      } else if (type == "flash_sale") {
        getFlashSale(id);
      } else {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => MyApp(sharedPreferences: prefs),
          ),
        );
      }
      Provider.of<SettingProvider>(context, listen: false)
          .setPrefrenceBool(ISFROMBACK, false);
    });
  }

  void generateChatLocalNotification(
      {required String title,
      required String body,
      required String payload}) async {
    if (Platform.isAndroid) {
      var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
        'your channel id',
        'your channel name',
        channelDescription: 'your channel description',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        playSound: true,
      );
      var iosDetail = const DarwinNotificationDetails();
      var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosDetail,
      );
      await flutterLocalNotificationsPlugin.show(
        0,
        title,
        body,
        platformChannelSpecifics,
        payload: 'chat,$payload',
      );
    }
  }

  void permission() async {
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> myBackgroundMessageHandler(RemoteMessage message) async {
    print("openNotification:background>${message.data}");
    setPrefrenceBool(ISFROMBACK, true);
    await Firebase.initializeApp();
  }

  Future<String> _downloadAndSaveImage(String url, String fileName) async {
    var directory = await getApplicationDocumentsDirectory();
    var filePath = '${directory.path}/$fileName';
    var response = await http.get(Uri.parse(url));

    var file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  Future<void> generateImageNotication(String title, String msg, String image,
      String type, String id, String url) async {
    if (Platform.isAndroid) {
      var largeIconPath = await _downloadAndSaveImage(image, 'largeIcon');
      var bigPicturePath = await _downloadAndSaveImage(image, 'bigPicture');
      var bigPictureStyleInformation = BigPictureStyleInformation(
          FilePathAndroidBitmap(bigPicturePath),
          hideExpandedLargeIcon: true,
          contentTitle: title,
          htmlFormatContentTitle: true,
          summaryText: msg,
          htmlFormatSummaryText: true);
      var androidPlatformChannelSpecifics = AndroidNotificationDetails(
          'big text channel id', 'big text channel name',
          channelDescription: 'big text channel description',
          largeIcon: FilePathAndroidBitmap(largeIconPath),
          styleInformation: bigPictureStyleInformation);
      var platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
          0, title, msg, platformChannelSpecifics,
          payload: "$type,$id,$url");
    }
  }

  DarwinNotificationDetails darwinNotificationDetails =
      DarwinNotificationDetails(
    categoryIdentifier: "",
  );

  Future<void> generateSimpleNotication(
      String title, String msg, String type, String id, String url) async {
    if (Platform.isAndroid) {
      var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
          'your channel id', 'your channel name',
          channelDescription: 'your channel description',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker');

      var platformChannelSpecifics = NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: darwinNotificationDetails);
      await flutterLocalNotificationsPlugin.show(
          0, title, msg, platformChannelSpecifics,
          payload: "$type,$id,$url");
    }
  }

  selectNotificationPayload(String? payload) async {
    if (payload != null) {
      print("all details $payload");
      List<String> pay = payload.split(",");
      print("pay is $pay");
      print("payload ${pay[0]}");
      if (pay[0] == "products") {
        context.read<PushNotificationProvider>().getProduct(pay[1], 0, 0, true);
      } else if (pay[0] == 'chat') {
        final whatWeNeed = payload.replaceFirst('${pay[0]},', '');
        if (converstationScreenStateKey.currentState?.mounted ?? false) {
          Navigator.of(context).pop();
        }
        final message = msg.Message.fromJson(jsonDecode(whatWeNeed));
        Routes.navigateToConverstationScreen(
            context: context,
            isGroup: false,
            personalChatHistory: PersonalChatHistory(
                unreadMsg: '1',
                opponentUserId: message.fromId,
                opponentUsername: message.sendersName,
                image: message.picture));
      } else if (pay[0] == "categories") {
        Future.delayed(Duration.zero, () {
          if (Dashboard.dashboardScreenKey.currentState != null) {
            Dashboard.dashboardScreenKey.currentState!.changeTabPosition(1);
          }
        });
      } else if (pay[0] == "wallet") {
        Navigator.pushNamed(context, Routers.myWalletScreen);
      } else if (pay[0] == 'order' || pay[0] == 'place_order') {
        // Navigator.push(context,
        //     (CupertinoPageRoute(builder: (context) => const MyOrder())));
        Navigator.pushNamed(context, Routers.myOrderScreen);
      } else if (pay[0] == "ticket_message") {
        Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) => Chat(
                    id: pay[1],
                    status: "",
                  )),
        );
      } else if (pay[0] == "ticket_status") {
        Navigator.push(context,
            CupertinoPageRoute(builder: (context) => const CustomerSupport()));
      } else if (pay[0] == "notification_url") {
        String url = pay[2].toString();
        try {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url),
                mode: LaunchMode.externalApplication);
          } else {
            throw 'Could not launch $url';
          }
        } catch (e) {
          throw 'Something went wrong';
        }
      } else if (pay[0] == "flash_sale") {
        getFlashSale(pay[1]);
      } else {
        Navigator.push(context,
            (CupertinoPageRoute(builder: (context) => const Splash())));
      }
    }
  }

  void _onTapChatNotification({required RemoteMessage message}) {
    if ((converstationScreenStateKey.currentState?.mounted) ?? false) {
      Navigator.of(context).pop();
    }

    final messages = jsonDecode(message.data['message']) as List;

    if (messages.isEmpty) {
      return;
    }

    final messageDetails =
        msg.Message.fromJson(jsonDecode(json.encode(messages.first)));

    Routes.navigateToConverstationScreen(
        context: context,
        isGroup: false,
        personalChatHistory: PersonalChatHistory(
            unreadMsg: '1',
            opponentUserId: messageDetails.fromId,
            opponentUsername: messageDetails.sendersName,
            image: messageDetails.picture));
  }

  void getFlashSale(String id) {
    try {
      apiBaseHelper.postAPICall(getFlashSaleApi, {}).then((getdata) {
        bool error = getdata["error"];

        context.read<FlashSaleProvider>().removeSaleList();

        if (!error) {
          var data = getdata["data"];

          List<FlashSaleModel> saleList = (data as List)
              .map((data) => FlashSaleModel.fromJson(data))
              .toList();
          context.read<FlashSaleProvider>().setSaleList(saleList);
          int index = saleList.indexWhere((element) => element.id == id);
          Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => FlashProductList(
                  index: index,
                ),
              ));
        }
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      });
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }
}
