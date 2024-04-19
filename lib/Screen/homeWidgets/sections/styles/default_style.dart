import 'package:eshop/Screen/homeWidgets/sections/blueprint.dart';
import 'package:eshop/Screen/homeWidgets/sections/styles/style_1.dart';
import 'package:flutter/material.dart';

class DefaultStyleSection extends FeaturedSection {
  @override
  String style = "default";

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
          //childAspectRatio: 0.8,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(
            products.length < 4 ? products.length : 4,
            (index) {
              return productItem(index, index, index % 2 == 0 ? true : false,
                  products[index], 1, products.length);
            },
          )),
    );
  }
}
