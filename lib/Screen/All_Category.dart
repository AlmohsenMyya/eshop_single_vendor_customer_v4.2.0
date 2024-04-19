import 'package:eshop/Helper/Color.dart';
import 'package:eshop/Helper/String.dart';
import 'package:eshop/Provider/CategoryProvider.dart';
import 'package:eshop/Provider/HomeProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../Helper/Session.dart';
import '../Model/Section_Model.dart';
import '../app/routes.dart';
import '../ui/styles/DesignConfig.dart';
import 'HomePage.dart';

class AllCategory extends StatefulWidget {
  const AllCategory({Key? key}) : super(key: key);

  @override
  AllCategoryState createState() => AllCategoryState();
}

class AllCategoryState extends State<AllCategory> {
  final ScrollController _scrollControllerOnCategory = ScrollController();
  final ScrollController _scrollControllerOnSubCategory = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    hideAppbarAndBottomBarOnScroll(_scrollControllerOnCategory, context);
    hideAppbarAndBottomBarOnScroll(_scrollControllerOnSubCategory, context);
    return Scaffold(
        body: Consumer<HomeProvider>(builder: (context, homeProvider, _) {
      if (homeProvider.catLoading) {
        return const Center(
          child: CircularProgressIndicator(
            color: colors.primary,
          ),
        );
      }
      return Row(
        children: [
          Expanded(
              flex: 1,
              child: Container(
                  color: Theme.of(context).colorScheme.lightWhite,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    controller: _scrollControllerOnCategory,
                    shrinkWrap: true,
                    scrollDirection: Axis.vertical,
                    padding: const EdgeInsetsDirectional.only(top: 10.0),
                    itemCount: catList.length,
                    itemBuilder: (context, index) {
                      return catItem(index, context);
                    },
                  ))),
          Expanded(
            flex: 3,
            child: catList.isNotEmpty
                ? Column(
                    children: [
                      Selector<CategoryProvider, int>(
                        builder: (context, data, child) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                        "${capitalize(catList[data].name!.toLowerCase())} "),
                                    const Expanded(
                                        child: Divider(
                                      thickness: 2,
                                    ))
                                  ],
                                ),
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: Text(
                                      "${getTranslated(context, 'All')!} ${capitalize(catList[data].name!.toLowerCase())} ",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium!
                                          .copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .fontColor,
                                          ),
                                    ))
                              ],
                            ),
                          );
                        },
                        selector: (_, cat) => cat.curCat,
                      ),
                      Expanded(
                          child: Selector<CategoryProvider, List<Product>>(
                        builder: (context, data, child) {
                          return data.isNotEmpty
                              ? GridView.count(
                                  physics: const BouncingScrollPhysics(
                                      parent: AlwaysScrollableScrollPhysics()),
                                  controller: _scrollControllerOnSubCategory,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  crossAxisCount: 3,
                                  shrinkWrap: true,
                                  childAspectRatio: .6,
                                  children: List.generate(
                                    data.length,
                                    (index) {
                                      return subCatItem(data, index, context);
                                    },
                                  ))
                              : Center(
                                  child:
                                      Text(getTranslated(context, 'noItem')!));
                        },
                        selector: (_, categoryProvider) =>
                            categoryProvider.subList,
                      )),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      );
    }));
  }

  Widget catItem(int index, BuildContext context1) {
    return Selector<CategoryProvider, int>(
      builder: (context, data, child) {
        if (index == 0 && (popularList.isNotEmpty)) {
          return InkWell(
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: data == index
                      ? Theme.of(context).canvasColor
                      : Theme.of(context).colorScheme.white,
                  border: data == index
                      ? const Border(
                          bottom: BorderSide(width: 0.5, color: colors.primary),
                          top: BorderSide(width: 0.5, color: colors.primary),
                          left: BorderSide(width: 5.0, color: colors.primary),
                        )
                      : null),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(25.0),
                        child: SvgPicture.asset(
                          data == index
                              ? "${imagePath}popular_sel.svg"
                              : "${imagePath}popular.svg",
                          colorFilter: const ColorFilter.mode(
                              colors.primary, BlendMode.srcIn),
                        )),
                  ),
                  Text(
                    "${capitalize(catList[index].name!.toLowerCase())}\n",
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context1).textTheme.bodySmall!.copyWith(
                        color: data == index
                            ? colors.primary
                            : Theme.of(context).colorScheme.fontColor),
                  )
                ],
              ),
            ),
            onTap: () {
              context1.read<CategoryProvider>().setCurSelected(index);
              context1.read<CategoryProvider>().setSubList(popularList);
            },
          );
        } else {
          return InkWell(
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: data == index
                      ? Theme.of(context).canvasColor
                      : Theme.of(context).colorScheme.white,
                  border: data == index
                      ? const Border(
                          left: BorderSide(width: 5.0, color: colors.primary),
                        )
                      : null),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: deviceWidth! / 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .fontColor
                                .withOpacity(0.042),
                            spreadRadius: 2,
                            blurRadius: 13,
                            offset: const Offset(
                                0, 0), // changes position of shadow
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                          radius: 45.0,
                          backgroundColor: Theme.of(context).colorScheme.white,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(45),
                            child: networkImageCommon(
                                catList[index].image!,
                                50,
                                width: deviceWidth! / 7.8,
                                height: double.maxFinite,
                                false),
                          )
                          /*CachedNetworkImage(
                            imageUrl: catList[index].image!,
                            fadeInDuration: const Duration(milliseconds: 150),
                            fit: BoxFit.fill,
                            errorWidget: (context, error, stackTrace) =>
                                erroWidget(50),
                            placeholder: (context,url) { return placeHolder(50);}
                          )*/
                          ),
                    ),
                  )),
                  Text(
                    "${capitalize(catList[index].name!.toLowerCase())}\n",
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context1).textTheme.bodySmall!.copyWith(
                        color: data == index
                            ? colors.primary
                            : Theme.of(context).colorScheme.fontColor),
                  )
                ],
              ),
            ),
            onTap: () {
              context1.read<CategoryProvider>().setCurSelected(index);
              if (catList[index].subList == null ||
                  catList[index].subList!.isEmpty) {
                context1.read<CategoryProvider>().setSubList([]);
                // Navigator.push(
                //     context1,
                //     CupertinoPageRoute(
                //       builder: (context) => ProductListScreen(
                //         name: catList[index].name,
                //         id: catList[index].id,
                //         tag: false,
                //         fromSeller: false,
                //       ),
                //     )).then((value) {
                //   context.read<CategoryProvider>().setCurSelected(0);
                // });

                Navigator.pushNamed(context1, Routers.productListScreen,
                    arguments: {
                      "name": catList[index].name,
                      "id": catList[index].id,
                      "tag": false,
                      "fromSeller": false,
                    }).then((value) {
                  context.read<CategoryProvider>().setCurSelected(0);
                });
                ;
              } else {
                context1
                    .read<CategoryProvider>()
                    .setSubList(catList[index].subList);
              }
            },
          );
        }
      },
      selector: (_, cat) => cat.curCat,
    );
  }

  subCatItem(List<Product> subList, int index, BuildContext context) {
    return InkWell(
      child: Column(
        children: <Widget>[
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .fontColor
                            .withOpacity(0.042),
                        spreadRadius: 2,
                        blurRadius: 13,
                        offset:
                            const Offset(0, 0), // changes position of shadow
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                      radius: 45.0,
                      backgroundColor: Theme.of(context).colorScheme.white,
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: networkImageCommon(
                              subList[index].image!, 50, false))
                      /*CachedNetworkImage(
                      imageUrl: subList[index].image!,
                      fadeInDuration: const Duration(milliseconds: 150),
                      fit: BoxFit.fill,
                      errorWidget: (context, error, stackTrace) =>
                          erroWidget(50),
                      placeholder: (context,url) {return placeHolder(50);}
                    ),*/
                      ))),
          Text(
            "${capitalize(subList[index].name!.toLowerCase())}\n",
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .bodySmall!
                .copyWith(color: Theme.of(context).colorScheme.fontColor),
          )
        ],
      ),
      onTap: () {
        if (context.read<CategoryProvider>().curCat == 0 &&
            popularList.isNotEmpty) {
          if (popularList[index].subList == null ||
              popularList[index].subList!.isEmpty) {
            // Navigator.push(
            //     context,
            //     CupertinoPageRoute(
            //       builder: (context) => ProductListScreen(
            //
            //       ),
            //     ));

            Navigator.pushNamed(context, Routers.productListScreen, arguments: {
              "name": popularList[index].name,
              "id": popularList[index].id,
              "tag": false,
              "fromSeller": false,
            });
          } else {
            // Navigator.push(
            //     context,
            //     CupertinoPageRoute(
            //       builder: (context) => SubCategoryScreen(),
            //     ));

            Navigator.pushNamed(context, Routers.subCategoryScreen, arguments: {
              "subList": popularList[index].subList,
              "title": popularList[index].name!.toUpperCase(),
            });
          }
        } else if (subList[index].subList == null ||
            subList[index].subList!.isEmpty) {
          Navigator.pushNamed(context, Routers.productListScreen, arguments: {
            "name": subList[index].name,
            "id": subList[index].id,
            "tag": false,
            "fromSeller": false,
          });
        } else {
          // Navigator.push(
          //     context,
          //     CupertinoPageRoute(
          //       builder: (context) => SubCategoryScreen(
          //
          //       ),
          //     ));

          Navigator.pushNamed(context, Routers.subCategoryScreen, arguments: {
            "subList": subList[index].subList,
            "title": subList[index].name!.toUpperCase(),
          });
        }
      },
    );
  }
}
