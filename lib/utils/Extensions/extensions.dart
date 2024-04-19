import 'package:flutter/cupertino.dart';

export 'lib/build_context.dart';
export 'lib/color.dart';
export 'lib/date.dart';
export 'lib/string.dart';
export 'lib/textWidgetExtention.dart';
export 'lib/translate.dart';

extension ScrollEndListen on ScrollController {
  ///It will check if scroll is at the bottom or not
  bool isEndReached() {
    if (offset >= position.maxScrollExtent) {
      return true;
    }
    return false;
  }
}
