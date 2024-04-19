import 'package:eshop/Screen/homeWidgets/sections/blueprint.dart';
import 'package:eshop/Screen/homeWidgets/sections/styles/default_style.dart';
import 'package:eshop/Screen/homeWidgets/sections/styles/else_style.dart';
import 'package:eshop/Screen/homeWidgets/sections/styles/style_1.dart';
import 'package:eshop/Screen/homeWidgets/sections/styles/style_2.dart';
import 'package:eshop/Screen/homeWidgets/sections/styles/style_3.dart';
import 'package:eshop/Screen/homeWidgets/sections/styles/style_4.dart';

import '../../../Model/Section_Model.dart';

class FeaturedSectionGet {
  List<FeaturedSection> featuredSections = [
    DefaultStyleSection(),
    StyleOneSection(),
    StyleTwoSection(),
    StyleThreeSection(),
    StyleFourSection(),
  ];

  FeaturedSection get(String style,
      {required int index, required List<Product> products}) {
    FeaturedSection section = featuredSections.firstWhere(
      (section) => section.style == style,
      orElse: () {
        return ElseStyleSection();
      },
    );
    section.index = index;
    section.products = products;
    return section;
  }
}
