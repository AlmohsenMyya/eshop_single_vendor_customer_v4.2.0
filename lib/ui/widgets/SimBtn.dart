import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Helper/Color.dart';

class SimBtn extends StatelessWidget {
  final String? title;
  final VoidCallback? onBtnSelected;
  double? width;
  double? height;

  SimBtn({Key? key, this.title, this.onBtnSelected, this.width, this.height})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width * width!;
    // height=height;
    return _buildBtnAnimation(context);
  }

  Widget _buildBtnAnimation(BuildContext context) {
    return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onBtnSelected,
        child: Container(
            width: width,
            height: height,
            alignment: FractionalOffset.center,
            decoration: const BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.all(Radius.circular(5.0)),
            ),
            child: Text(title!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: colors.whiteTemp, fontWeight: FontWeight.normal))));
  }
}
