import 'package:eshop/Helper/Color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Model/OfferImages.dart';
import '../../Model/Section_Model.dart';
import '../../app/routes.dart';
import '../../ui/styles/DesignConfig.dart';
import '../SubCategory.dart';

class PopupOfferDialog extends StatelessWidget {
  final PopUpOfferImage popupOffer;
  final Function() onDialogClick;
  const PopupOfferDialog(
      {super.key, required this.onDialogClick, required this.popupOffer});

  void show(BuildContext context) async {
    try {
      SharedPreferences sharedData = await SharedPreferences.getInstance();
      sharedData.setString("offerPopUpID", popupOffer.id.toString());
      if (popupOffer.showMultipleTime == "1") {}
      Future.delayed(
        Duration.zero,
        () async {
          dialogAnimate(context, StatefulBuilder(
              builder: (BuildContext context, StateSetter setStater) {
            return PopupOfferDialog(
              onDialogClick: () {},
              popupOffer: popupOffer,
            );
          }));
        },
      );
    } catch (e) {
      print("error ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(5.0))),
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          onDialogClick.call();
          popUpOfferImageClick(context);
        },
        child: Container(
          // color: Colors.red,
          margin: const EdgeInsets.only(left: 0.0, right: 0.0),
          child: Stack(
            children: <Widget>[
              Container(
                  /*  padding: const EdgeInsets.only(
                      top: 18.0,
                    ),*/
                  margin:
                      const EdgeInsets.only(top: 13.0, right: 8.0, left: 8.0),
                  height: MediaQuery.of(context).size.height * 0.5,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(15.0),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: (Theme.of(context).colorScheme.white)
                              .withOpacity(0.5),
                          blurRadius: 0.0,
                          offset: const Offset(0.0, 0.0),
                        ),
                      ]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: networkImageCommon(
                        popupOffer?.image ?? "",
                        50,
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height * 0.5,
                        false,
                        boxFit: BoxFit.fill),
                  )),
              Positioned(
                right: 0.0,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Align(
                    alignment: Alignment.topRight,
                    child: CircleAvatar(
                      radius: 16.0,
                      backgroundColor: (Theme.of(context).colorScheme.white)
                          .withOpacity(0.7),
                      child: Icon(Icons.close,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  popUpOfferImageClick(BuildContext context) async {
    Navigator.pop(context);
    if (popupOffer.type == "products") {
      String id = popupOffer.data![0].id!;
      // currentHero = homeHero;

      Navigator.pushNamed(context, Routers.productDetails, arguments: {
        "secPos": 0,
        "index": 0,
        "list": true,
        "id": id,
      });
    } else if (popupOffer.type == "categories") {
      Product item = popupOffer.data!;
      if (item.subList == null || item.subList!.isEmpty) {
        // Navigator.push(
        //     context,
        //     CupertinoPageRoute(
        //       builder: (context) => ProductListScreen(
        //
        //       ),
        //     ));

        Navigator.pushNamed(context, Routers.productListScreen, arguments: {
          "name": item.name,
          "id": item.id,
          "tag": false,
          "fromSeller": false,
          "maxDis": popupOffer.maxDiscount,
          "minDis": popupOffer.minDiscount,
        });
      } else {
        // Navigator.push(
        //     context,
        //     CupertinoPageRoute(
        //       builder: (context) => SubCategoryScreen(),
        //     ));
        Navigator.pushNamed(context, Routers.subCategoryScreen, arguments: {
          "title": item.name!,
          "subList": item.subList,
          "maxDis": popupOffer.maxDiscount,
          "minDis": popupOffer.minDiscount,
        });
      }
    } else if (popupOffer.type == "all_products") {
      // Navigator.push(
      //     context,
      //     CupertinoPageRoute(
      //       builder: (context) => ProductListScreen(
      //
      //       ),
      //     ));

      Navigator.pushNamed(context, Routers.productListScreen, arguments: {
        "tag": false,
        "fromSeller": false,
        "maxDis": popupOffer.maxDiscount,
        "minDis": popupOffer.minDiscount,
      });
    } else if (popupOffer.type == "brand") {
      // Navigator.push(
      //     context,
      //     CupertinoPageRoute(
      //       builder: (context) => ProductListScreen(
      //
      //       ),
      //     ));

      Navigator.pushNamed(context, Routers.productListScreen, arguments: {
        "tag": false,
        "fromSeller": false,
        "maxDis": popupOffer.maxDiscount,
        "minDis": popupOffer.minDiscount,
        "brandId": popupOffer.typeId,
        "name": popupOffer.data![0].name!,
      });
    } else if (popupOffer.type == "offer_url") {
      String url = popupOffer.urlLink.toString();
      try {
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch $url';
        }
      } catch (e) {
        throw 'Something went wrong';
      }
    }
  }
}
