import 'package:eshop/Helper/Color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../Helper/Session.dart';
import '../../Provider/UserProvider.dart';
import '../../Screen/Cart.dart';
import '../../app/routes.dart';
import '../styles/DesignConfig.dart';

getAppBar(String title, BuildContext context, {int? from}) {
  return AppBar(
    elevation: 0,
    titleSpacing: 0,
    backgroundColor: Theme.of(context).colorScheme.white,
    leading: Builder(builder: (BuildContext context) {
      return Container(
        margin: const EdgeInsets.all(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => Navigator.of(context).pop(),
          child: const Center(
            child: Icon(
              Icons.arrow_back_ios_rounded,
              color: colors.primary,
            ),
          ),
        ),
      );
    }),
    title: Text(
      title,
      style:
          const TextStyle(color: colors.primary, fontWeight: FontWeight.normal),
    ),
    actions: <Widget>[
      from == 1
          ? const SizedBox()
          : IconButton(
              icon: SvgPicture.asset(
                "${imagePath}search.svg",
                height: 20,
                colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.blackInverseInDarkTheme,
                    BlendMode.srcIn),
              ),
              onPressed: () {
                // Navigator.push(
                //     context,
                //     CupertinoPageRoute(
                //       builder: (context) =>  SearchScreen(),
                //     ));

                Navigator.pushNamed(
                  context,
                  Routers.searchScreen,
                );
              }),
      from == 1
          ? const SizedBox()
          : title == getTranslated(context, 'FAVORITE')!
              ? const SizedBox.shrink()
              : IconButton(
                  padding: const EdgeInsets.all(0),
                  icon: SvgPicture.asset(
                    "${imagePath}desel_fav.svg",
                    colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.blackInverseInDarkTheme,
                        BlendMode.srcIn),
                  ),
                  onPressed: () {
                    // Navigator.push(
                    //     context,
                    //     CupertinoPageRoute(
                    //       builder: (context) => const Favorite(),
                    //     ));

                    Navigator.pushNamed(
                      context,
                      Routers.favoriteScreen,
                    );

                    ///
                    ///
                    ///
                    ///
                    ///
                    ///
                  },
                ),
      from == 1
          ? const SizedBox()
          : Selector<UserProvider, String>(
              builder: (context, data, child) {
                return IconButton(
                  icon: Stack(
                    children: [
                      Center(
                          child: SvgPicture.asset(
                        "${imagePath}appbarCart.svg",
                        colorFilter: ColorFilter.mode(
                            Theme.of(context)
                                .colorScheme
                                .blackInverseInDarkTheme,
                            BlendMode.srcIn),
                      )),
                      (data.isNotEmpty && data != "0")
                          ? Positioned(
                              bottom: 20,
                              right: 0,
                              child: Container(
                                  //  height: 20,
                                  decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colors.primary),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(3),
                                      child: Text(
                                        data,
                                        style: TextStyle(
                                            fontSize: 7,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .white),
                                      ),
                                    ),
                                  )),
                            )
                          : const SizedBox.shrink()
                    ],
                  ),
                  onPressed: () {
                    cartTotalClear();
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const Cart(
                          fromBottom: false,
                        ),
                      ),
                    );
                  },
                );
              },
              selector: (_, homeProvider) => homeProvider.curCartCount,
            )
    ],
  );
}
