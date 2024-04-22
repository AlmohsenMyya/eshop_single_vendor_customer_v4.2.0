import 'dart:async';
import 'dart:convert';

import 'package:bottom_bar/bottom_bar.dart';
import 'package:eshop/Helper/Color.dart';
import 'package:eshop/Helper/Constant.dart';
import 'package:eshop/Helper/PushNotificationService.dart';
import 'package:eshop/Helper/Session.dart';
import 'package:eshop/Helper/SqliteData.dart';
import 'package:eshop/Helper/String.dart';
import 'package:eshop/Model/Section_Model.dart';
import 'package:eshop/Model/message.dart';
import 'package:eshop/Provider/HomeProvider.dart';
import 'package:eshop/Provider/UserProvider.dart';
import 'package:eshop/Screen/Cart.dart';
import 'package:eshop/Screen/FlashSale.dart';
import 'package:eshop/Screen/MyProfile.dart';
import 'package:eshop/cubits/personalConverstationsCubit.dart';
import 'package:eshop/repository/notificationRepository.dart';
import 'package:eshop/utils/blured_router.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../Provider/SettingProvider.dart';
import '../app/routes.dart';
import '../cubits/fetch_featured_sections_cubit.dart';
import '../ui/styles/DesignConfig.dart';
import 'All_Category.dart';
import 'HomePage.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  static GlobalKey<HomePageState> dashboardScreenKey =
      GlobalKey<HomePageState>();
  static route(RouteSettings settings) {
    return BlurredRouter(
      builder: (context) {
        return Dashboard(
          key: dashboardScreenKey,
        );
      },
    );
  }

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<Dashboard>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _selBottom = 0;

  final PageController _pageController = PageController();
  bool _isNetworkAvail = true;
  var db = DatabaseHelper();
  late AnimationController navigationContainerAnimationController =
      AnimationController(
    vsync: this, // the SingleTickerProviderStateMixin
    duration: const Duration(milliseconds: 400),
  );
  FirebaseDynamicLinks dynamicLinks = FirebaseDynamicLinks.instance;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.delayed(Duration.zero, () {
      final pushNotificationService = PushNotificationService(context: context);
      pushNotificationService.initialise();
    });
    NotificationRepository.clearChatNotifications();
    initDynamicLinks();
    //dashboardPageState = GlobalKey<HomePageState>();
    db.getTotalCartCount(context);
    /* final pushNotificationService = PushNotificationService(
        context: context, pageController: _pageController);
    pushNotificationService.initialise(); */

    Future.delayed(Duration.zero, () async {
      SettingProvider settingsProvider =
          Provider.of<SettingProvider>(context, listen: false);
      context
          .read<UserProvider>()
          .setUserId(await settingsProvider.getPrefrence(ID) ?? '');

      context
          .read<HomeProvider>()
          .setAnimationController(navigationContainerAnimationController);
    });
  }

  changeTabPosition(int index) {
    Future.delayed(Duration.zero, () {
      _pageController.animateToPage(index,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      NotificationRepository.getChatNotifications().then((messages) {
        for (var encodedMessage in messages) {
          final message =
              Message.fromJson(Map.from(jsonDecode(encodedMessage) ?? {}));

          if (converstationScreenStateKey.currentState?.mounted ?? false) {
            final state = converstationScreenStateKey.currentState!;
            if (state.widget.isGroup) {
              //To manage the group
            } else {
              //
              if (state.widget.personalChatHistory?.getOtherUserId() !=
                  message.fromId) {
                context
                    .read<PersonalConverstationsCubit>()
                    .updateUnreadMessageCounter(userId: message.fromId!);
              } else {
                state.addMessage(message: message);
              }
            }
          } else {
            if (message.type == 'person') {
              context
                  .read<PersonalConverstationsCubit>()
                  .updateUnreadMessageCounter(
                    userId: message.fromId!,
                  );
            } else {
              // Update group message
            }
          }
        }
        //Clear the message notifications
        NotificationRepository.clearChatNotifications();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selBottom == 0,
      onPopInvoked: (didPop) {
        if (_selBottom != 0) {
          _pageController.animateToPage(0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut);
        }
      },
      child: SafeArea(
          top: false,
          bottom: true,
          child: Consumer<UserProvider>(builder: (context, data, child) {
            return Scaffold(
              extendBody: true,
              backgroundColor: Theme.of(context).colorScheme.lightWhite,
              appBar: _getAppBar(),
              body: PageView(
                controller: _pageController,
                children: const [
                  HomePage(),
                  AllCategory(),
                  // FlashSale(),
                  // Sale(),
                  Cart(
                    fromBottom: true,
                  ),
                  MyProfile()
                ],
                onPageChanged: (index) {
                  setState(() {
                    if (!context
                        .read<HomeProvider>()
                        .animationController
                        .isAnimating) {
                      context
                          .read<HomeProvider>()
                          .animationController
                          .reverse();
                      context.read<HomeProvider>().showBars(true);
                    }
                    _selBottom = index;
                    if (index == 3) {
                      cartTotalClear();
                    }
                  });
                },
              ),
              bottomNavigationBar: _getBottomBar(),
            );
          })),
    );
  }

  void initDynamicLinks() async {
    dynamicLinks.onLink.listen((dynamicLinkData) {
      final Uri deepLink = dynamicLinkData.link;

      if (deepLink.queryParameters.isNotEmpty) {
        int index = int.parse(deepLink.queryParameters['index']!);

        int secPos = int.parse(deepLink.queryParameters['secPos']!);

        String? id = deepLink.queryParameters['id'];

        String? list = deepLink.queryParameters['list'];

        getProduct(id!, index, secPos, list == "true" ? true : false);
      }
    }).onError((e) {
      print(e.message);
    });

    final PendingDynamicLinkData? data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri? deepLink = data?.link;
    if (deepLink != null) {
      if (deepLink.queryParameters.isNotEmpty) {
        int index = int.parse(deepLink.queryParameters['index']!);

        int secPos = int.parse(deepLink.queryParameters['secPos']!);

        String? id = deepLink.queryParameters['id'];

        getProduct(id!, index, secPos, true);
      }
    }
  }

  Future<void> getProduct(String id, int index, int secPos, bool list) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          ID: id,
        };

        apiBaseHelper.postAPICall(getProductApi, parameter).then((getdata) {
          bool error = getdata["error"];
          String msg = getdata["message"];
          if (!error) {
            var data = getdata["data"];

            List<Product> items = [];
            List<SectionModel> featuredSections = context
                .watch<FetchFeaturedSectionsCubit>()
                .getFeaturedSections();
            items =
                (data as List).map((data) => Product.fromJson(data)).toList();
            currentHero = homeHero;

            Navigator.pushNamed(context, Routers.productDetails, arguments: {
              "index": list ? int.parse(id) : index,
              "id": list
                  ? items[0].id!
                  : featuredSections[secPos].productList![index].id!,
              "secPos": secPos,
              "list": list,
            });
          } else {
            if (msg != "Products Not Found !") setSnackbar(msg, context);
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      {
        if (mounted) {
          setState(() {
            setSnackbar(getTranslated(context, 'NO_INTERNET_DISC')!, context);
          });
        }
      }
    }
  }

  AppBar _getAppBar() {
    String? title;
    if (_selBottom == 1) {
      title = getTranslated(context, 'CATEGORY');
    } else if (_selBottom == 2) {
      title = getTranslated(context, 'MYBAG');
      // title = getTranslated(context, 'OFFER');
    } else if (_selBottom == 3) {
      title = getTranslated(context, 'PROFILE');
      // title = getTranslated(context, 'MYBAG');
    } else if (_selBottom == 4) {
      // title = getTranslated(context, 'PROFILE');
    }

    return AppBar(
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      title: _selBottom == 0
          ? SvgPicture.asset(
              'assets/images/titleicon.svg',
              height: 35,
              colorFilter:
                  const ColorFilter.mode(colors.primary, BlendMode.srcIn),
            )
          : Text(
              title!,
              style: const TextStyle(
                  color: colors.primary, fontWeight: FontWeight.normal),
            ),
      actions: <Widget>[
        IconButton(
          icon: SvgPicture.asset(
            "${imagePath}desel_notification.svg",
            colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.blackInverseInDarkTheme,
                BlendMode.srcIn),
          ),
          onPressed: () {
            final userProvider = context.read<UserProvider>();
            if (userProvider.userId != "") {
              Navigator.pushNamed(
                context,
                Routers.notificationListScreen,
              ).then((value) {
                if (value != null && value == true) {
                  _pageController.jumpToPage(1);
                }
              });
            } else {
              Navigator.pushNamed(
                context,
                Routers.loginScreen,
                arguments: {
                  "isPop": true,
                  "classType": Dashboard(
                    key: Dashboard.dashboardScreenKey,
                  )
                },
              );
            }
          },
        ),
        IconButton(
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
          },
        ),
      ],
      backgroundColor: Theme.of(context).colorScheme.lightWhite,
    );
  }

  Widget _getBottomBar() {
    return FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(
            parent: navigationContainerAnimationController,
            curve: Curves.easeInOut)),
        child: SlideTransition(
          position:
              Tween<Offset>(begin: Offset.zero, end: const Offset(0.0, 1.0))
                  .animate(CurvedAnimation(
                      parent: navigationContainerAnimationController,
                      curve: Curves.easeInOut)),
          child: Container(
            // height: ,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.white,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20))),
            child: BottomBar(
              height: 60,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              selectedIndex: _selBottom,
              onTap: (int index) {
                _pageController.jumpToPage(index);
                setState(() => _selBottom = index);
              },

              //itemPadding: EdgeInsets.zero,
              items: <BottomBarItem>[
                BottomBarItem(
                  icon: _selBottom == 0
                      ? SvgPicture.asset(
                          "${imagePath}sel_home.svg",
                          colorFilter: const ColorFilter.mode(
                              colors.primary, BlendMode.srcIn),
                          width: 18,
                          height: 20,
                        )
                      : SvgPicture.asset(
                          "${imagePath}desel_home.svg",
                          colorFilter: const ColorFilter.mode(
                              colors.primary, BlendMode.srcIn),
                          width: 18,
                          height: 20,
                        ),
                  title: Text(
                      getTranslated(
                        context,
                        'HOME_LBL',
                      )!,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true),
                  activeColor: colors.primary,
                ),
                BottomBarItem(
                    icon: _selBottom == 1
                        ? SvgPicture.asset(
                            "${imagePath}category01.svg",
                            colorFilter: const ColorFilter.mode(
                                colors.primary, BlendMode.srcIn),
                            width: 18,
                            height: 18,
                          )
                        : SvgPicture.asset(
                            "${imagePath}category.svg",
                            colorFilter: const ColorFilter.mode(
                                colors.primary, BlendMode.srcIn),
                            width: 18,
                            height: 18,
                          ),
                    title: Text(getTranslated(context, 'category')!,
                        overflow: TextOverflow.ellipsis, softWrap: true),
                    activeColor: colors.primary),
                // BottomBarItem(
                //   icon: _selBottom == 2
                //       ? SvgPicture.asset(
                //           "${imagePath}sale02.svg",
                //           colorFilter: const ColorFilter.mode(
                //               colors.primary, BlendMode.srcIn),
                //           width: 18,
                //           height: 20,
                //         )
                //       : SvgPicture.asset(
                //           "${imagePath}sale.svg",
                //           colorFilter: const ColorFilter.mode(
                //               colors.primary, BlendMode.srcIn),
                //           width: 18,
                //           height: 20,
                //         ),
                //   title: Text(getTranslated(context, 'SALE')!,
                //       overflow: TextOverflow.ellipsis, softWrap: true),
                //   activeColor: colors.primary,
                // ),
                BottomBarItem(
                  icon: Selector<UserProvider, String>(
                    builder: (context, data, child) {
                      return Stack(
                        children: [
                          _selBottom == 2
                              ? SvgPicture.asset(
                                  "${imagePath}cart01.svg",
                                  colorFilter: const ColorFilter.mode(
                                      colors.primary, BlendMode.srcIn),
                                  width: 18,
                                  height: 20,
                                )
                              : SvgPicture.asset(
                                  "${imagePath}cart.svg",
                                  colorFilter: const ColorFilter.mode(
                                      colors.primary, BlendMode.srcIn),
                                  width: 18,
                                  height: 20,
                                ),
                          (data.isNotEmpty && data != "0")
                              ? Positioned.directional(
                                  end: 0,
                                  textDirection: Directionality.of(context),
                                  top: 0,
                                  child: Container(
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
                      );
                    },
                    selector: (_, homeProvider) => homeProvider.curCartCount,
                  ),
                  title: Text(getTranslated(context, 'CART')!,
                      overflow: TextOverflow.ellipsis, softWrap: true),
                  activeColor: colors.primary,
                ),
                BottomBarItem(
                  icon: _selBottom == 3
                      ? SvgPicture.asset(
                          "${imagePath}profile01.svg",
                          colorFilter: const ColorFilter.mode(
                              colors.primary, BlendMode.srcIn),
                          width: 18,
                          height: 20,
                        )
                      : SvgPicture.asset(
                          "${imagePath}profile.svg",
                          width: 18,
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                              colors.primary, BlendMode.srcIn),
                        ),
                  title: Text(getTranslated(context, 'PROFILE')!,
                      overflow: TextOverflow.ellipsis, softWrap: true),
                  activeColor: colors.primary,
                ),
              ],
            ),
          ),
        ));
  }
}
