import 'package:flutter/cupertino.dart';

class MyBehavior extends ScrollBehavior {
  Widget glowingOverscrollIndicator(
      BuildContext context, Widget child, AxisDirection details) {
    return child;
  }
}
