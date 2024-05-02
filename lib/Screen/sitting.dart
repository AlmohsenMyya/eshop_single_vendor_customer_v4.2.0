import 'package:eshop/Helper/Color.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../Helper/Constant.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import '../Helper/routes.dart';
import '../Provider/UserProvider.dart';
import '../app/routes.dart';
import '../ui/styles/DesignConfig.dart';
import 'Customer_Support.dart';
import 'Faqs.dart';
import 'MyProfile.dart';
import 'Privacy_Policy.dart';
import 'ReferEarn.dart';

class Sittingnew extends StatefulWidget {
  const Sittingnew({super.key});

  @override
  State<Sittingnew> createState() => _SittingnewState();
}

class _SittingnewState extends State<Sittingnew> {
  final InAppReview _inAppReview = InAppReview.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(

        body: Consumer<UserProvider>(builder: (context, data, child) {
      return Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                _getDrawer(),
              ],
            ),
          ),
        ],
      );
    }));
  }

  _getDrawer() {
    return Padding(
      padding: const EdgeInsets.only(top: 108.0),
      child: ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        children: <Widget>[
          // context.read<UserProvider>().userId == ""
          //     ? const SizedBox.shrink()
          //     : _getDrawerItem(getTranslated(context, 'MY_ORDERS_LBL')!,
          //         'assets/images/pro_myorder.svg'),
          // CUR_USERID == "" || CUR_USERID == null ? SizedBox.shrink() : _getDivider(),
          context.read<UserProvider>().userId == ""
              ? const SizedBox.shrink()
              : _getDrawerItem(getTranslated(context, 'MANAGE_ADD_LBL')!,
                  'assets/images/pro_address.svg'),
          //CUR_USERID == "" || CUR_USERID == null ? SizedBox.shrink() : _getDivider(),
          context.read<UserProvider>().userId == ""
              ? const SizedBox.shrink()
              : _getDrawerItem(getTranslated(context, 'MYWALLET')!,
                  'assets/images/pro_wh.svg'),
          context.read<UserProvider>().userId == ""
              ? const SizedBox.shrink()
              : _getDrawerItem(getTranslated(context, 'YOUR_PROM_CO')!,
                  'assets/images/promo.svg'),
          // CUR_USERID == "" || CUR_USERID == null ? SizedBox.shrink() : _getDivider(),
          context.read<UserProvider>().userId == ""
              ? const SizedBox.shrink()
              : _getDrawerItem(getTranslated(context, 'MYTRANSACTION')!,
                  'assets/images/pro_th.svg'),
          // CUR_USERID == "" || CUR_USERID == null ? SizedBox.shrink() : _getDivider(),

          if (disableDarkTheme == false) ...{
            _getDrawerItem(getTranslated(context, 'CHANGE_THEME_LBL')!,
                'assets/images/pro_theme.svg'),
          },

          // _getDivider(),
          // _getDrawerItem(getTranslated(context, 'CHANGE_LANGUAGE_LBL')!,
          //     'assets/images/pro_language.svg'),
          //  CUR_USERID == "" || CUR_USERID == null ? SizedBox.shrink() : _getDivider(),
          context.read<UserProvider>().userId == "" ||
                  context.read<UserProvider>().loginType != PHONE_TYPE
              ? const SizedBox.shrink()
              : _getDrawerItem(getTranslated(context, 'CHANGE_PASS_LBL')!,
                  'assets/images/pro_pass.svg'),
          // _getDivider(),
          context.read<UserProvider>().userId == "" || !refer
              ? const SizedBox.shrink()
              : _getDrawerItem(getTranslated(context, 'REFEREARN')!,
                  'assets/images/pro_referral.svg'),
          // CUR_USERID == "" || CUR_USERID == null ? SizedBox.shrink() : _getDivider(),
          context.read<UserProvider>().userId == ""
              ? const SizedBox.shrink()
              : _getDrawerItem(getTranslated(context, 'CUSTOMER_SUPPORT')!,
                  'assets/images/pro_customersupport.svg'),
          // _getDivider(),
          context.read<UserProvider>().userId == ''
              ? const SizedBox()
              : _getDrawerItem(
                  getTranslated(context, 'CHAT')!, 'assets/images/pro_chat.svg'),
          _getDrawerItem(getTranslated(context, 'ABOUT_LBL')!,
              'assets/images/pro_aboutus.svg'),
          // _getDivider(),
          _getDrawerItem(getTranslated(context, 'CONTACT_LBL')!,
              'assets/images/pro_contact_us.svg'),
          // _getDivider(),
          _getDrawerItem(
              getTranslated(context, 'FAQS')!, 'assets/images/pro_faq.svg'),
          // _getDivider(),
          _getDrawerItem(
              getTranslated(context, 'PRIVACY')!, 'assets/images/pro_pp.svg'),
          // _getDivider(),
          _getDrawerItem(
              getTranslated(context, 'TERM')!, 'assets/images/pro_tc.svg'),
          _getDrawerItem(getTranslated(context, 'SHIPPING_PO_LBL')!,
              'assets/images/shipping_policy.svg'),
          // _getDivider(),
          _getDrawerItem(getTranslated(context, 'RETURN_PO_LBL')!,
              'assets/images/return_policy.svg'),
          // _getDivider(),
          _getDrawerItem(
              getTranslated(context, 'RATE_US')!, 'assets/images/pro_rateus.svg'),
          // _getDivider(),
          _getDrawerItem(getTranslated(context, 'SHARE_APP')!,
              'assets/images/pro_share.svg'),

        ],
      ),
    );
  }

  _getDrawerItem(String title, String img) {
    return Card(
      // color: colors.whiteTemp,
      elevation: 0,
      child: ListTile(
        trailing: Icon(
          Icons.navigate_next,
          color: Theme.of(context).colorScheme.blackInverseInDarkTheme,
        ),
        dense: false,
        leading: title == getTranslated(context, 'DEL_ACC_LBL')
            ? const Icon(
                Icons.delete,
                size: 25,
                color: colors.primary,
              )
            : SvgPicture.asset(
                img,
                height: 25,
                width: 25,
                colorFilter:
                    const ColorFilter.mode(colors.primary, BlendMode.srcIn),
              ),
        title: Text(
          title,
          style: TextStyle(
              color: Theme.of(context).colorScheme.lightBlack,
              fontSize: 15,
              fontWeight: FontWeight.normal),
        ),
        onTap: () {
          if (title == getTranslated(context, 'MY_ORDERS_LBL')) {
            // Navigator.push(
            //     context,
            //     CupertinoPageRoute(
            //       builder: (context) => const MyOrder(),
            //     ));
            Navigator.pushNamed(context, Routers.myOrderScreen);
            //sendAndRetrieveMessage();
          } else if (title == getTranslated(context, 'MYTRANSACTION')) {
            Navigator.pushNamed(context, Routers.transactionHistoryScreen);
          } else if (title == getTranslated(context, 'MYWALLET')) {
            // Navigator.push(
            //     context,
            //     CupertinoPageRoute(
            //       builder: (context) => const MyWalletScreen(),
            //     ));

            Navigator.pushNamed(context, Routers.myWalletScreen);
          } else if (title == getTranslated(context, 'YOUR_PROM_CO')) {
            // Navigator.push(
            //     context,
            //     CupertinoPageRoute(
            //       builder: (context) => const PromoCodeScreen(from: "Profile"),
            //     ));
            Navigator.pushNamed(context, Routers.promoCodeScreen,
                arguments: {"from": "Profile"});
          } else if (title == getTranslated(context, 'MANAGE_ADD_LBL')) {
            Navigator.pushNamed(context, Routers.manageAddressScreen,
                arguments: {
                  "home": true,
                });
          } else if (title == getTranslated(context, 'REFEREARN')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const ReferEarn(),
                ));
          } else if (title == getTranslated(context, 'CONTACT_LBL')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => PrivacyPolicy(
                    title: getTranslated(context, 'CONTACT_LBL'),
                  ),
                ));
          } else if (title == getTranslated(context, 'CHAT')) {
            Routes.navigateToConverstationListScreen(context);
          } else if (title == getTranslated(context, 'CUSTOMER_SUPPORT')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (context) => const CustomerSupport()));
          } else if (title == getTranslated(context, 'TERM')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => PrivacyPolicy(
                    title: getTranslated(context, 'TERM'),
                  ),
                ));
          } else if (title == getTranslated(context, 'PRIVACY')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => PrivacyPolicy(
                    title: getTranslated(context, 'PRIVACY'),
                  ),
                ));
          } else if (title == getTranslated(context, 'RATE_US')) {
            _openStoreListing();
          } else if (title == getTranslated(context, 'SHARE_APP')) {
            var str =
                "$appName\n\n${getTranslated(context, 'APPFIND')}$androidLink$packageName\n\n ${getTranslated(context, 'IOSLBL')}\n$iosLink";

            Share.share(str);
          } else if (title == getTranslated(context, 'ABOUT_LBL')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => PrivacyPolicy(
                    title: getTranslated(context, 'ABOUT_LBL'),
                  ),
                ));
          } else if (title == getTranslated(context, 'SHIPPING_PO_LBL')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => PrivacyPolicy(
                    title: getTranslated(context, 'SHIPPING_PO_LBL'),
                  ),
                ));
          } else if (title == getTranslated(context, 'RETURN_PO_LBL')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => PrivacyPolicy(
                    title: getTranslated(context, 'RETURN_PO_LBL'),
                  ),
                ));
          } else if (title == getTranslated(context, 'FAQS')) {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => Faqs(
                    title: getTranslated(context, 'FAQS'),
                  ),
                ));
          }
        },
      ),
    );
  }
  Future<void> _openStoreListing() => _inAppReview.openStoreListing(
    appStoreId: appStoreId,
    microsoftStoreId: 'microsoftStoreId',
  );

}
