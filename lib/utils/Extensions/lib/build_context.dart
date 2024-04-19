import 'package:flutter/material.dart';

// 10pt: Smaller
// 12pt: Small
// 16pt: Large
// 18pt: Larger
// 24pt: Extra large
extension TextThemeForFont on TextTheme {
  Font get font => Font();
}

extension CustomContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  //This one for colorScheme shortcut
  ColorScheme get color => Theme.of(this).colorScheme;

//This one for fontSize
  ///I created different Font class to limit textTheme values, let's assume if some one is using context.font and he is getting too may options related to text theme so how will he know which one is for use??
  ///So in theme.dart file i have created Font class which will give limited numbers of getters
  Font get font => Theme.of(this).textTheme.font;
}

class Font {
  ///10
  double get smaller => 10;

  ///12
  double get small => 12;

  ///14
  double get normal => 14;

  ///16
  double get large => 16;

  ///18
  double get larger => 18;

  ///24
  double get extraLarge => 24;

  ///28
  double get xxLarge => 28;
}
