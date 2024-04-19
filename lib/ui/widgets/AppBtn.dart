import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Helper/Color.dart';

class AppBtn extends StatelessWidget {
  final String? title;
  final AnimationController? btnCntrl;
  final Animation? btnAnim;
  final VoidCallback? onBtnSelected;

  const AppBtn(
      {Key? key, this.title, this.btnCntrl, this.btnAnim, this.onBtnSelected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final initialWidth = btnAnim!.value;
    return AnimatedBuilder(
      builder: (c, child) => _buildBtnAnimation(
        c,
        child,
        initialWidth: initialWidth,
      ),
      animation: btnCntrl!,
    );
  }

  Widget _buildBtnAnimation(BuildContext context, Widget? child,
      {required double initialWidth}) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: CupertinoButton(
        child: Container(
          width: btnAnim!.value,
          height: 45,
          alignment: FractionalOffset.center,
          decoration: const BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
          child: btnAnim!.value > 75.0
              ? Text(title!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: colors.whiteTemp, fontWeight: FontWeight.normal))
              : const CircularProgressIndicator(
                  color: colors.primary,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.whiteTemp),
                ),
        ),
        onPressed: () {
          //if it's not loading do the thing
          if (btnAnim!.value == initialWidth) {
            onBtnSelected!();
          }
        },
      ),
    );
  }
}
