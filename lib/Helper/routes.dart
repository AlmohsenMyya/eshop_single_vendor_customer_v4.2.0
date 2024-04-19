import 'package:eshop/Helper/Constant.dart';
import 'package:eshop/Model/groupDetails.dart';
import 'package:eshop/Model/personalChatHistory.dart';
import 'package:eshop/Screen/chat/converstationListScreen.dart';
import 'package:eshop/Screen/chat/converstationScreen.dart';
import 'package:eshop/Screen/chat/searchAdminScreen.dart';
import 'package:eshop/cubits/converstationCubit.dart';
import 'package:eshop/cubits/searchAdminCubit.dart';
import 'package:eshop/cubits/sendMessageCubit.dart';
import 'package:eshop/repository/adminDetailsRepository.dart';
import 'package:eshop/repository/chatRepository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Routes {
  ///
  ///Chat related navitation function
  ///
  static navigateToConverstationListScreen(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => ConverstationListScreen(
          key: converstationListScreenStateKey,
        ),
      ),
    );
  }

  static navigateToConverstationScreen(
      {required BuildContext context,
      PersonalChatHistory? personalChatHistory,
      GroupDetails? groupDetails,
      required bool isGroup}) {
    converstationScreenStateKey = GlobalKey<ConverstationScreenState>();
    Navigator.of(context).push(CupertinoPageRoute(
        builder: (_) => MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) => ConverstationCubit(ChatRepository()),
                  ),
                  BlocProvider(
                      create: (_) => SendMessageCubit(ChatRepository()))
                ],
                child: ConverstationScreen(
                    groupDetails: groupDetails,
                    key: converstationScreenStateKey,
                    isGroup: isGroup,
                    personalChatHistory: personalChatHistory))));
  }

  static navigateToSearchSellerScreen(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => SearchAdminCubit(AdminDetailRepository()),
          child: const SearchAdminScreen(),
        ),
      ),
    );
  }

  static navigateToGroupInfoScreen(
      BuildContext context, GroupDetails groupDetails) {
    // Navigator.push(
    //   context,
    //   CupertinoPageRoute(
    //     builder: (context) => GroupInfoScreen(groupDetails: groupDetails),
    //   ),
    // );
  }
}
