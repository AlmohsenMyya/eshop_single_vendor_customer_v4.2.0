import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:eshop/Provider/SettingProvider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:eshop/Helper/Session.dart';
import 'package:eshop/Helper/String.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../Helper/Color.dart';
import '../Model/Model.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

import '../ui/styles/DesignConfig.dart';
import '../ui/widgets/AppBarWidget.dart';
import 'HomePage.dart';

class Chat extends StatefulWidget {
  final String? id, status;

  const Chat({Key? key, this.id, this.status}) : super(key: key);

  @override
  _ChatState createState() => _ChatState();
}

StreamController<String>? chatstreamdata;

class _ChatState extends State<Chat> {
  TextEditingController msgController = TextEditingController();
  List<File> files = [];
  List<Model> chatList = [];
  late Map<String?, String> downloadlist;
  String _filePath = "";

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    downloadlist = <String?, String>{};
    CUR_TICK_ID = widget.id;
    FlutterDownloader.registerCallback(downloadCallback);
    setupChannel();

    getMsg();
  }

  @override
  void dispose() {
    CUR_TICK_ID = '';
    if (chatstreamdata != null) chatstreamdata!.sink.close();

    super.dispose();
  }

  static void downloadCallback(String id, int status, int progress) {
    final SendPort send =
        IsolateNameServer.lookupPortByName('downloader_send_port')!;
    send.send([id, status, progress]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAppBar(getTranslated(context, 'CHAT')!, context),
      body: Column(
        children: <Widget>[buildListMessage(), msgRow()],
      ),
    );
  }

  void setupChannel() {
    chatstreamdata = StreamController<String>();
    chatstreamdata!.stream.listen((response) {
      setState(() {
        final res = json.decode(response);
        Model message;
        message = Model.fromChat(res["data"]);

        chatList.insert(0, message);
        files.clear();
      });
    });
  }

  void insertItem(String response) {
    if (chatstreamdata != null) chatstreamdata!.sink.add(response);
    _scrollController.animateTo(0.0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Widget buildListMessage() {
    return Flexible(
      child: ListView.builder(
        padding: const EdgeInsets.all(10.0),
        itemBuilder: (context, index) => msgItem(index, chatList[index]),
        itemCount: chatList.length,
        reverse: true,
        controller: _scrollController,
      ),
    );
  }

  Widget msgItem(int index, Model message) {
    if (message.uid == context.read<SettingProvider>().userId) {
      //Own message
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          const Flexible(
            flex: 1,
            child: SizedBox.shrink(),
          ),
          Flexible(
            flex: 2,
            child: MsgContent(index, message),
          ),
        ],
      );
    } else {
      //Other's message
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Flexible(
            flex: 2,
            child: MsgContent(index, message),
          ),
          const Flexible(
            flex: 1,
            child: SizedBox.shrink(),
          ),
        ],
      );
    }
  }

  Widget MsgContent(int index, Model message) {
    SettingProvider settingsProvider =
        Provider.of<SettingProvider>(context, listen: false);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: message.uid == settingsProvider.userId
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: <Widget>[
        message.uid == settingsProvider.userId
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(left: 5.0),
                      child: Text(capitalize(message.name!),
                          style: const TextStyle(
                              color: colors.primary, fontSize: 12)),
                    )
                  ],
                ),
              ),
        ListView.builder(
            itemBuilder: (context, index) {
              return attachItem(message.attach!, index, message);
            },
            itemCount: message.attach!.length,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true),
        message.msg != null && message.msg!.isNotEmpty
            ? Card(
                elevation: 0.0,
                color: message.uid == settingsProvider.userId
                    ? Theme.of(context).colorScheme.fontColor.withOpacity(0.1)
                    : Theme.of(context).colorScheme.white,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
                  child: Column(
                    crossAxisAlignment: message.uid == settingsProvider.userId
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: <Widget>[
                      Text("${message.msg}",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.black)),
                      Padding(
                        padding: const EdgeInsetsDirectional.only(top: 5),
                        child: Text(message.date!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.lightBlack,
                                fontSize: 9)),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  void _requestDownload(String? url, String? mid) async {
    bool checkpermission = await Checkpermission();
    if (checkpermission) {
      if (Platform.isIOS) {
        Directory target = await getApplicationDocumentsDirectory();
        _filePath = target.path.toString();
      } else {
        _filePath = '/storage/emulated/0/Download';
        if (!await Directory(_filePath).exists()) {
          Directory? target = await getExternalStorageDirectory();
          _filePath = target!.path.toString();
        }
      }

      String fileName = url!.substring(url.lastIndexOf("/") + 1);
      File file = File("$_filePath/$fileName");
      bool hasExisted = await file.exists();

      if (downloadlist.containsKey(mid)) {
        final tasks = await FlutterDownloader.loadTasksWithRawQuery(
            query:
                "SELECT status FROM task WHERE task_id=${downloadlist[mid]}");

        if (tasks == 4 || tasks == 5) downloadlist.remove(mid);
      }

      if (hasExisted) {
        final openFile = await OpenFilex.open("$_filePath/$fileName");
      } else if (downloadlist.containsKey(mid)) {
        setSnackbar(getTranslated(context, 'Downloading')!, context);
      } else {
        setSnackbar(getTranslated(context, 'Downloading')!, context);
        final taskid = await FlutterDownloader.enqueue(
            url: url,
            savedDir: _filePath,
            headers: {"auth": "test_for_sql_encoding"},
            showNotification: true,
            openFileFromNotification: true);

        setState(() {
          downloadlist[mid] = taskid.toString();
        });
      }
    }
  }

  Future<bool> Checkpermission() async {
    var status = await Permission.storage.status;

    if (status != PermissionStatus.granted) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
      ].request();

      if (statuses[Permission.storage] == PermissionStatus.granted) {
        FileDirectoryPrepare();
        return true;
      }
    } else {
      FileDirectoryPrepare();
      return true;
    }
    return false;
  }

  Future<void> FileDirectoryPrepare() async {
    if (Platform.isIOS) {
      Directory target = await getApplicationDocumentsDirectory();
      _filePath = target.path.toString();
    } else {
      _filePath = '/storage/emulated/0/Download';
      if (!await Directory(_filePath).exists()) {
        Directory? target = await getExternalStorageDirectory();
        _filePath = target!.path.toString();
      }
    }
  }

  _imgFromGallery() async {
    try {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(allowMultiple: true);
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

  Future<void> sendMessage(String message) async {
    SettingProvider settingsProvider =
        Provider.of<SettingProvider>(context, listen: false);

    setState(() {
      msgController.text = "";
    });
    var request = http.MultipartRequest("POST", sendMsgApi);
    request.headers.addAll(headers);
    request.fields[USER_ID] = settingsProvider.userId!;
    request.fields[TICKET_ID] = widget.id!;
    request.fields[USER_TYPE] = USER;
    request.fields[MESSAGE] = message;

    for (int i = 0; i < files.length; i++) {
      final mimeType = lookupMimeType(files[i].path);

      var extension = mimeType!.split("/");
      var pic = await http.MultipartFile.fromPath(
        ATTACH,
        files[i].path,
        contentType: MediaType('image', extension[1]),
      );
      request.files.add(pic);
    }

    var response = await request.send();
    var responseData = await response.stream.toBytes();
    var responseString = String.fromCharCodes(responseData);
    var getdata = json.decode(responseString);

    bool error = getdata["error"];
    String? msg = getdata['message'];
    var data = getdata["data"];
    if (!error) {
      insertItem(responseString);
    }
  }

  Future<void> getMsg() async {
    try {
      var data = {
        TICKET_ID: widget.id,
      };

      apiBaseHelper.postAPICall(getMsgApi, data).then((getdata) {
        bool error = getdata["error"];
        String? msg = getdata["message"];

        if (!error) {
          var data = getdata["data"];
          chatList =
              (data as List).map((data) => Model.fromChat(data)).toList();
        } else {
          if (msg != "Ticket Message(s) does not exist") {
            setSnackbar(msg!, context);
          }
        }
        if (mounted) setState(() {});
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      });
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg')!, context);
    }
  }

  msgRow() {
    return widget.status != "4"
        ? Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              width: double.infinity,
              color: Theme.of(context).colorScheme.white,
              child: Row(
                children: <Widget>[
                  InkWell(
                    onTap: () {
                      _imgFromGallery();
                    },
                    child: Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(
                        Icons.add,
                        color: Theme.of(context).colorScheme.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 15,
                  ),
                  Expanded(
                    child: TextField(
                      controller: msgController,
                      style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          color: Theme.of(context).colorScheme.fontColor),
                      maxLines: null,
                      decoration: InputDecoration(
                          hintText: "Write message...",
                          hintStyle: TextStyle(
                              color: Theme.of(context).colorScheme.lightBlack),
                          border: InputBorder.none),
                    ),
                  ),
                  const SizedBox(
                    width: 15,
                  ),
                  FloatingActionButton(
                    mini: true,
                    onPressed: () {
                      if (msgController.text.trim().isNotEmpty ||
                          files.isNotEmpty) {
                        sendMessage(msgController.text.trim());
                      }
                    },
                    backgroundColor: colors.primary,
                    elevation: 0,
                    child: Icon(
                      Icons.send,
                      color: Theme.of(context).colorScheme.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          )
        : const SizedBox.shrink();
  }

  Widget attachItem(List<attachment> attach, int index, Model message) {
    String? file = attach[index].media;
    String? type = attach[index].type;
    String icon;
    if (type == "video") {
      icon = "assets/images/video.svg";
    } else if (type == "document") {
      icon = "assets/images/doc.svg";
    } else if (type == "spreadsheet") {
      icon = "assets/images/sheet.svg";
    } else {
      icon = "assets/images/zip.svg";
    }
    SettingProvider settingsProvider =
        Provider.of<SettingProvider>(context, listen: false);
    return file == null
        ? const SizedBox.shrink()
        : Stack(
            alignment: Alignment.bottomRight,
            children: <Widget>[
              Card(
                elevation: 0.0,
                color: message.uid == settingsProvider.userId
                    ? Theme.of(context).colorScheme.fontColor.withOpacity(0.1)
                    : Theme.of(context).colorScheme.white,
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Column(
                    crossAxisAlignment: message.uid == settingsProvider.userId
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: <Widget>[
                      InkWell(
                        onTap: () {
                          _requestDownload(attach[index].media, message.id);
                        },
                        child: type == "image"
                            ? Image.network(file,
                                width: 250,
                                height: 150,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    erroWidget(150))
                            : SvgPicture.asset(
                                icon,
                                width: 100,
                                height: 100,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Text(message.date!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.lightBlack,
                          fontSize: 9)),
                ),
              ),
            ],
          );
  }
}
