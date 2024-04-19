import 'dart:async';
import 'package:eshop/Helper/Session.dart';
import 'package:eshop/Provider/FlashSaleProvider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../Helper/String.dart';
import '../Helper/Color.dart';

class MultipleTimer extends StatefulWidget {
  final String startDateModel;
  final String endDateModel;
  final String serverDateModel;
  final String id;
  final int newtimeDiff;
  final int from;
  final bool? inDetails;

  const MultipleTimer(
      {Key? key,
      required this.startDateModel,
      required this.endDateModel,
      required this.serverDateModel,
      required this.id,
      required this.newtimeDiff,
      required this.from,
      this.inDetails})
      : super(key: key);

  @override
  _MultipleTimerState createState() => _MultipleTimerState();
}

class _MultipleTimerState extends State<MultipleTimer>
    with TickerProviderStateMixin {
  Timer? timer;
  int? timeDiff;
  int? timeDiff1;

  late StreamController streamController;
  bool? isSaleFuture;
  DateTime? startDate, endDate, serverDate;

  @override
  void initState() {
    setupChannel();

    startDate = DateTime.parse(widget.startDateModel);
    endDate = DateTime.parse(widget.endDateModel);

    serverDate = DateFormat("yy-MM-dd HH:mm:ss").parse(widget.serverDateModel);

    if (startDate!.isAfter(serverDate!)) {
      isSaleFuture = true;
      timeDiff = startDate!.difference(serverDate!).inSeconds;
      if (timeDiff != null) {
        if (widget.newtimeDiff == 0) {
          timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
            handleTick();
          });
        } else {
          //timer = widget.newtimer;
          timeDiff = widget.newtimeDiff;
          timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
            handleTick();
          });
        }
        // setState(() {});
      }
    } else {
      isSaleFuture = false;

      timeDiff1 = endDate!.difference(serverDate!).inSeconds;
      if (timeDiff1 != null) {
        if (widget.newtimeDiff == 0) {
          timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
            handleTick1();
          });
        } else {
          timeDiff1 = widget.newtimeDiff;
          setState(() {});


          timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
            handleTick1();
          });
        }
      }
    }

    // flashSaleData();

    super.initState();
  }

  @override
  void dispose() {
    timer!.cancel();
    streamController.close();
    super.dispose();
  }

  void setupChannel() {
    streamController = StreamController<int>.broadcast();
  }

  void handleTick() {
    if (timeDiff! > 0) {
      if ((isSaleFuture! ? startDate : endDate!) != serverDate!) {
        timeDiff = timeDiff! - 1;
        if (!streamController.isClosed) {
          if (widget.inDetails == null) {
            streamController.sink.add(timeDiff);
            context.read<FlashSaleProvider>().setDiffTime(timeDiff!, widget.id);
          } else {
            streamController.sink.add(timeDiff);
          //  context.read<ProductDetailProvider>().setDiffTime(timeDiff!);
          }
        }
      }
    } else {
      isSaleFuture = false;
      timeDiff = null;

      if (mounted) {
        timeDiff1 = endDate!.difference(serverDate!).inSeconds;

        if (timeDiff1 != null) {
          timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
            handleTick1();
          });
        }
      }
    }
  }

  void handleTick1() {
    if (timeDiff1! > 0) {
      if ((isSaleFuture! ? startDate : endDate!) != serverDate!) {
        timeDiff1 = timeDiff1! - 1;
        if (!streamController.isClosed) {
          if (widget.inDetails == null) {
            streamController.sink.add(timeDiff1);
            context
                .read<FlashSaleProvider>()
                .setDiffTime(timeDiff1!, widget.id, isSaleOn: "1");
          } else {
            streamController.sink.add(timeDiff1);
            /*context
                .read<ProductDetailProvider>()
                .setDiffTime(timeDiff1!, isSaleOn: "1");*/
          }
        }
      }
    } else {
      if (widget.inDetails == null) {
        context
            .read<FlashSaleProvider>()
            .setDiffTime(0, widget.id, isSaleOn: "0");
      } else {
       // context.read<ProductDetailProvider>().setDiffTime(0, isSaleOn: "0");
      }

      timeDiff1 = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: streamController.stream,
      builder: (
        BuildContext context,
        snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        } else if (snapshot.connectionState == ConnectionState.active ||
            snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return const Text('Error');
          } else if (snapshot.hasData && snapshot.data != null) {
            int time1 = snapshot.data;

            Duration duration = Duration(seconds: time1);

            return time1 > 0
                ? widget.from == 1
                    ? Text(
                        "${isSaleFuture! ? getTranslated(context, 'OFFER_SALE_START_LBL')! : getTranslated(context, 'OFFER_SALE_END_LBL')!} \n ${duration.inDaysRest > 0 ? ("${duration.inDaysRest.toString().padLeft(2, '0')} days") : ""}  "
                        "${duration.inHoursRest.toString().padLeft(2, '0')} h : ${duration.inMinutesRest.toString().padLeft(2, '0')} m : ${duration.inSecondsRest.toString().padLeft(2, '0')} s",
                        maxLines: 3,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: Theme.of(context).colorScheme.fontColor),
                      )
                    : Card(
                        elevation: 0,
                        child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            color: colors.primary.withOpacity(0.3),
                            padding: const EdgeInsetsDirectional.only(
                                start: 5.0, end: 5.0),
                            width: deviceWidth,
                            child: Text(
                              "${isSaleFuture! ? getTranslated(context, 'OFFER_SALE_START_LBL')! : getTranslated(context, 'OFFER_SALE_END_LBL')!} \n${duration.inDaysRest > 0 ? ("${duration.inDaysRest.toString().padLeft(2, '0')} days") : ""}  "
                              "${duration.inHoursRest.toString().padLeft(2, '0')} h : ${duration.inMinutesRest.toString().padLeft(2, '0')} m : ${duration.inSecondsRest.toString().padLeft(2, '0')} s",
                              maxLines: 3,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall!
                                  .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .fontColor),
                            )))
                : const SizedBox();
          } else {
            return const Text('Empty data');
          }
        } else {
          return Text('State: ${snapshot.connectionState}');
        }
      },
    );
  }
}

extension RestTimeOnDuration on Duration {
  int get inDaysRest => inDays;

  int get inHoursRest => inHours - (inDays * 24);

  int get inMinutesRest => inMinutes - (inHours * 60);

  int get inSecondsRest => inSeconds - (inMinutes * 60);

  int get inMillisecondsRest => inMilliseconds - (inSeconds * 1000);

  int get inMicrosecondsRest => inMicroseconds - (inMilliseconds * 1000);
}
