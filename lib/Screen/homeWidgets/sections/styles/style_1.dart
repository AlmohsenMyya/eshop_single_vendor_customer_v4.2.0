import 'package:eshop/Screen/homeWidgets/sections/blueprint.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../Model/Section_Model.dart';
import '../featured_section_product_item.dart';

class StyleOneSection extends FeaturedSection {
  @override
  String style = "style_1";

  @override
  Widget render(BuildContext context) {
    Orientation orient = MediaQuery.of(context).orientation;
    double height = MediaQuery.of(context).size.height;

    return Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          children: [
            Flexible(
                flex: 3,
                fit: FlexFit.loose,
                child: SizedBox(
                    height:
                        orient == Orientation.portrait ? height * 0.4 : height,
                    child: products.length == 1 || products.length > 1
                        ? productItem(
                            index, 0, true, products[0], 1, products.length)
                        : const SizedBox.shrink())),
            Flexible(
              flex: 2,
              fit: FlexFit.loose,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                      height: orient == Orientation.portrait
                          ? height * 0.2
                          : height * 0.5,
                      child: products.length == 2 || products.length > 2
                          ? productItem(
                              index, 1, false, products[1], 1, products.length)
                          : const SizedBox.shrink()),
                  SizedBox(
                      height: orient == Orientation.portrait
                          ? height * 0.2
                          : height * 0.5,
                      child: products.length == 3 || products.length > 3
                          ? productItem(
                              index, 2, false, products[2], 1, products.length)
                          : const SizedBox.shrink()),
                ],
              ),
            ),
          ],
        ));
  }
}

Widget productItem(int sectionPosition, int index, bool pad, Product product,
    int from, int length) {
  if (length > index) {
    String? offerPersontage;
    double price = double.parse(product.prVarientList![0].disPrice!);
    if (price == 0) {
      price = double.parse(product.prVarientList![0].price!);
    } else {
      double off = double.parse(product.prVarientList![0].price!) - price;
      offerPersontage =
          ((off * 100) / double.parse(product.prVarientList![0].price!))
              .toStringAsFixed(2);
    }

    return FeaturedProductItem(
      price: price,
      offerPersontage: offerPersontage,
      product: product,
      sectionPosition: sectionPosition,
      index: index,
    );
  } else {
    return const SizedBox.shrink();
  }
}
