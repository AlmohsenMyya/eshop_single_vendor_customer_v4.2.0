import 'package:eshop/Screen/homeWidgets/sections/styles/style_1.dart';
import 'package:flutter/material.dart';

import '../blueprint.dart';

class ElseStyleSection extends FeaturedSection {
  @override
  String style = "";

  @override
  Widget render(BuildContext context) {
    Orientation orient = MediaQuery.of(context).orientation;
    double height = MediaQuery.of(context).size.height;
    return Padding(
        padding: const EdgeInsets.all(15.0),
        child: GridView.count(
            padding: const EdgeInsetsDirectional.only(top: 5),
            crossAxisCount: 2,
            shrinkWrap: true,
            childAspectRatio: 1.2,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 0,
            crossAxisSpacing: 0,
            children: List.generate(
              products!.length < 6 ? products.length : 6,
              (index) {
                return productItem(index, index, index % 2 == 0 ? true : false,
                    products[index], 1, products.length);
              },
            )));
  }
}
