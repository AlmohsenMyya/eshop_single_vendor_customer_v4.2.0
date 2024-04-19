import 'package:eshop/Model/Section_Model.dart';
import 'package:flutter/material.dart';

abstract class FeaturedSection {
  List<Product> products = [];
  int index=0;
  abstract String style;
  Widget render(BuildContext context);
}
