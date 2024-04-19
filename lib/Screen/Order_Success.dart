import 'package:eshop/Helper/Color.dart';
import 'package:eshop/Helper/Session.dart';
import 'package:eshop/Screen/Dashboard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../Helper/String.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/widgets/AppBarWidget.dart';
import '../utils/blured_router.dart';

class OrderSuccess extends StatefulWidget {
  const OrderSuccess({Key? key}) : super(key: key);
  static route(RouteSettings settings) {
    Map? arguments = settings.arguments as Map?;
    return BlurredRouter(
      builder: (context) {
        return const OrderSuccess();
      },
    );
  }

  @override
  State<StatefulWidget> createState() {
    return StateSuccess();
  }
}

class StateSuccess extends State<OrderSuccess> {
  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: getAppBar(getTranslated(context, 'ORDER_PLACED')!, context),
      body: Center(
        child: SingleChildScrollView(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              margin: const EdgeInsets.symmetric(vertical: 40),
              child: SvgPicture.asset(
                "${imagePath}bags.svg",
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                getTranslated(context, 'ORD_PLC')!,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(color: Theme.of(context).colorScheme.fontColor),
              ),
            ),
            Text(
              getTranslated(context, 'ORD_PLC_SUCC')!,
              style: TextStyle(color: Theme.of(context).colorScheme.fontColor),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 28.0),
              child: CupertinoButton(
                child: Container(
                    width: deviceWidth! * 0.7,
                    height: 45,
                    alignment: FractionalOffset.center,
                    decoration: const BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                    ),
                    child: Text(getTranslated(context, 'CONTINUE_SHOPPING')!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: Theme.of(context).colorScheme.white,
                            fontWeight: FontWeight.normal))),
                onPressed: () {
                  Navigator.of(context)
                      .pushReplacement(MaterialPageRoute(builder: (context) {
                    Dashboard.dashboardScreenKey = GlobalKey<HomePageState>();
                    return Dashboard(
                      key: Dashboard.dashboardScreenKey,
                    );
                  }));
                },
              ),
            )
          ],
        )),
      ),
    );
  }
}
