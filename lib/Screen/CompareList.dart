import 'package:eshop/Helper/Session.dart';
import 'package:eshop/Model/Section_Model.dart';
import 'package:eshop/Provider/ProductDetailProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';

import '../Helper/Color.dart';
import '../Helper/String.dart';
import '../app/routes.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/widgets/AppBarWidget.dart';
import '../ui/widgets/BehaviorWidget.dart';

class CompareList extends StatefulWidget {
  const CompareList({Key? key}) : super(key: key);

  @override
  _CompareListState createState() => _CompareListState();
}

class _CompareListState extends State<CompareList> {
  int maxLength = 0;

  @override
  void initState() {
    List val = [];

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      List compareList = context.read<ProductDetailProvider>().compareList;
      for (int i = 0;
          i < context.read<ProductDetailProvider>().compareList.length;
          i++) {
        if (compareList[i]!.prVarientList![0].attr_name != "") {
          val.add(
              compareList[i]!.prVarientList![0].attr_name!.split(',').length);
        }
      }
      if (val.isNotEmpty) {
        maxLength = val.reduce((curr, next) => curr > next ? curr : next);
        setState(() {});
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: getAppBar(getTranslated(context, 'COMPARE_PRO')!, context),
        body: Selector<ProductDetailProvider, List<Product>>(
          builder: (context, data, child) {
            return data.isEmpty
                ? getNoItem(context)
                : ScrollConfiguration(
                    behavior: MyBehavior(),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: data.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        return listItem(index, data);
                      },
                    ));
          },
          selector: (_, categoryProvider) => categoryProvider.compareList,
        ));
  }

  Widget listItem(int index, List<Product> compareList) {
    Product model = compareList[index];
    String? gaurantee = compareList[index].gurantee;
    String? returnable = compareList[index].isReturnable;
    String? cancleable = compareList[index].isCancelable;
    if (cancleable == "1") {
      cancleable = "Till ${compareList[index].cancleTill!}";
    } else {
      cancleable = "No";
    }
    String? warranty = compareList[index].warranty;

    String? madeIn = compareList[index].madein;

    double price =
        double.parse(model.prVarientList![model.selVarient!].disPrice!);
    if (price == 0) {
      price = double.parse(model.prVarientList![model.selVarient!].price!);
    }
    List att = [], val = [];
    if (model.prVarientList![model.selVarient!].attr_name != "") {
      att = model.prVarientList![model.selVarient!].attr_name!.split(',');
      val = model.prVarientList![model.selVarient!].varient_value!.split(',');
    }
    return SingleChildScrollView(
      child: Card(
        elevation: 0,
        child: SizedBox(
          width: deviceWidth! * 0.5,
          child: InkWell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextButton.icon(
                    onPressed: () {
                      setState(() {
                        compareList.removeWhere(
                            (item) => item.id == compareList[index].id);
                        List val = [];
                        for (int i = 0; i < compareList.length; i++) {
                          if (compareList[i].prVarientList![0].attr_name !=
                              "") {
                            val.add(compareList[i]
                                .prVarientList![0]
                                .attr_name!
                                .split(',')
                                .length);
                          }
                        }
                        if (val.isNotEmpty) {
                          maxLength = val.reduce(
                              (curr, next) => curr > next ? curr : next);
                        }
                      });
                    },
                    icon: const Icon(Icons.close),
                    label: const Text("Remove")),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Hero(
                      tag: "$compHero$index${model.id}0",
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(5),
                            topRight: Radius.circular(5)),
                        child: networkImageCommon(
                            model.image!, deviceWidth! * 0.5, false,
                            height: deviceWidth! * 0.5,
                            width: deviceWidth! * 0.5),
                        /*CachedNetworkImage(
                            imageUrl: model.image!,
                            height: deviceWidth! * 0.5,
                            width: deviceWidth! * 0.5,
                            fadeInDuration: const Duration(milliseconds: 150),
                            fit: extendImg ? BoxFit.fill : BoxFit.contain,
                            errorWidget: (context, error, stackTrace) =>
                                erroWidget(deviceWidth! * 0.5),
                            placeholder: (context, url) {
                              return placeHolder(deviceWidth! * 0.5);
                            }),*/
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.center,
                      child: model.availability == "0"
                          ? Container(
                              color: Theme.of(context).colorScheme.white70,
                              padding: const EdgeInsets.all(2),
                              child: Text(
                                  getTranslated(context, 'OUT_OF_STOCK_LBL')!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall!
                                      .copyWith(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold)),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: RatingBarIndicator(
                    rating: double.parse(model.rating!),
                    itemBuilder: (context, index) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    itemCount: 5,
                    itemSize: 12.0,
                    direction: Axis.horizontal,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Text(
                    "${model.name!}\n",
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsetsDirectional.only(start: 5.0, bottom: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        double.parse(model.prVarientList![model.selVarient!]
                                    .disPrice!) !=
                                0
                            ? getPriceFormat(
                                context,
                                double.parse(model
                                    .prVarientList![model.selVarient!].price!))!
                            : "",
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            decoration: TextDecoration.lineThrough,
                            letterSpacing: 1),
                      ),
                      Text(
                          model.isSalesOn == "1"
                              ? getPriceFormat(
                                  context,
                                  double.parse(model
                                      .prVarientList![model.selVarient!]
                                      .saleFinalPrice!))!
                              : '${getPriceFormat(context, price)!} ',
                          style: const TextStyle(color: colors.primary)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: Row(
                    children: [
                      Expanded(
                          child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 5.0),
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: maxLength,
                              itemBuilder: (context, index) {
                                if (model.prVarientList![model.selVarient!]
                                            .attr_name !=
                                        "" &&
                                    model.prVarientList![model.selVarient!]
                                        .attr_name!.isNotEmpty &&
                                    index < att.length) {
                                  return Row(children: [
                                    Flexible(
                                      child: Text(
                                        att[index].trim() + ":",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                          start: 5.0),
                                      child: Text(
                                        val[index],
                                        maxLines: 1,
                                        overflow: TextOverflow.visible,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  ]);
                                } else {
                                  return const Text(" ");
                                }
                              })),
                    ],
                  ),
                ),
                _madeIn(madeIn),
                _warrenty(warranty),
                _gaurantee(gaurantee),
                _returnable(returnable),
                _cancleable(cancleable),
              ],
            ),
            onTap: () {
              Product? model = compareList[index];
              currentHero = compHero;

              Navigator.pushNamed(context, Routers.productDetails, arguments: {
                "secPos": 0,
                "index": index,
                "list": true,
                "id": model.id!,
              });

              ///
            },
          ),
        ),
      ),
    );
  }

  _gaurantee(String? gaurantee) {
    return ListTile(
      trailing: Text(gaurantee!.isNotEmpty ? gaurantee : "-"),
      dense: true,
      title: Text(
        getTranslated(context, 'GAURANTEE')!,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }

  _returnable(String? returnable) {
    if (returnable == "1") {
      returnable = "${RETURN_DAYS!} Days";
    } else {
      returnable = "No";
    }
    return ListTile(
      trailing: Text(returnable),
      dense: true,
      title: Text(
        getTranslated(context, 'RETURNABLE')!,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }

  _cancleable(String? pos) {
    return ListTile(
      trailing: Text(pos ?? ""),
      dense: true,
      title: Text(
        getTranslated(context, 'CANCELLABLE')!,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }

  _warrenty(String? warranty) {
    return ListTile(
      trailing: Text(warranty!.isNotEmpty ? warranty : "-"),
      dense: true,
      title: Text(
        getTranslated(context, 'WARRENTY')!,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }

  _madeIn(String? madeIn) {
    return ListTile(
      trailing: Text(madeIn!.isNotEmpty ? madeIn : "-"),
      dense: true,
      title: Text(
        getTranslated(context, 'MADE_IN')!,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}
