import 'package:eshop/Helper/Color.dart';
import 'package:flutter/material.dart';

Widget setHeadTitle(String title,BuildContext context) {
  return Padding(
      padding: const EdgeInsetsDirectional.only(start: 12.0, end: 15.0),
      child: Text(title,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: Theme.of(context).colorScheme.fontColor)));
}