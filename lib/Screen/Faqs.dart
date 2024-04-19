import 'dart:async';
import 'package:eshop/Helper/Session.dart';
import 'package:eshop/Model/Faqs_Model.dart';
import 'package:eshop/Screen/HomePage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/widgets/AppBtn.dart';
import '../Helper/Color.dart';
import '../Helper/String.dart';
import '../ui/widgets/SimpleAppBar.dart';

class Faqs extends StatefulWidget {
  final String? title;

  const Faqs({Key? key, this.title}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StateFaqs();
  }
}

class StateFaqs extends State<Faqs> with TickerProviderStateMixin {
  bool _isLoading = true;
  String? privacy;
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;
  List<FaqsModel> faqsList = [];
  int selectedIndex = -1;
  bool flag = true;
  bool isLoadingmore = true;
  ScrollController controller = ScrollController();

  @override
  void initState() {
    super.initState();
    controller.addListener(_scrollListener);
    getFaqs();
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
    controller.removeListener(() {});
    super.dispose();
  }

  _scrollListener() {
    if (controller.offset >= controller.position.maxScrollExtent &&
        !controller.position.outOfRange) {
      if (mounted) {
        if (mounted) {
          setState(() {
            isLoadingmore = true;
            getFaqs();
          });
        }
      }
    }
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
    return Scaffold(
       // key: _scaffoldKey,
        appBar: getSimpleAppBar(widget.title!, context),
        body: _isNetworkAvail ? _showForm(context) : noInternet(context));
  }

  _showForm(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(10.0),
        child: _isLoading
            ? shimmer(context)
            : ListView.builder(
                controller: controller,
                itemCount: faqsList.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return (index == faqsList.length && isLoadingmore)
                      ? const Center(
                          child: CircularProgressIndicator(
                          color: colors.primary,
                        ))
                      : listItem(index);
                },
              ));
  }

  listItem(int index) {
    return Card(
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () {
            if (mounted) {
              setState(() {
                selectedIndex = index;
                flag = !flag;
              });
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        faqsList[index].question!,
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            color: Theme.of(context).colorScheme.lightBlack),
                      )),
                  selectedIndex != index || flag
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Text(
                                      faqsList[index].answer!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall!
                                          .copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .black
                                                  .withOpacity(0.7)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ))),
                            const Icon(Icons.keyboard_arrow_down)
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                              Expanded(
                                  child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0),
                                      child: Text(
                                        faqsList[index].answer!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall!
                                            .copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .black
                                                    .withOpacity(0.7)),
                                      ))),
                              const Icon(Icons.keyboard_arrow_up)
                            ]),
                ]),
          ),
        ));
  }

  Future<void> getFaqs() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        Map param = {};

        apiBaseHelper.postAPICall(getFaqsApi, param).then((getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            var data = getdata["data"];
            faqsList =
                (data as List).map((data) => FaqsModel.fromJson(data)).toList();
          } else {
            setSnackbar(msg!,context);
          }

          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }, onError: (error) {
          setSnackbar(error.toString(),context);
        });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!,context);
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isNetworkAvail = false;
        });
      }
    }
  }


}
