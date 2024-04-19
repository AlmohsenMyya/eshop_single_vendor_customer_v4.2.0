import 'dart:async';
import 'package:eshop/Helper/Color.dart';
import 'package:eshop/Helper/Session.dart';
import 'package:eshop/Helper/String.dart';
import 'package:eshop/Helper/routes.dart';
import 'package:eshop/Model/personalChatHistory.dart';
import 'package:eshop/cubits/searchAdminCubit.dart';
import 'package:eshop/ui/widgets/errorContainer.dart';
import 'package:eshop/ui/widgets/noInternet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchAdminScreen extends StatefulWidget {
  const SearchAdminScreen({Key? key}) : super(key: key);

  @override
  State<SearchAdminScreen> createState() => _SearchAdminScreenState();
}

class _SearchAdminScreenState extends State<SearchAdminScreen>
    with TickerProviderStateMixin {
  late AnimationController buttonController;
  late Animation buttonSqueezeanimation;

  late final TextEditingController searchQueryTextEditingController =
      TextEditingController()..addListener(searchQueryTextControllerListener);

  Timer? waitForNextSearchRequestTimer;

  int waitForNextRequestSearchQueryTimeInMilliSeconds = 500;

  @override
  void initState() {
    super.initState();
    buttonController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    buttonSqueezeanimation = Tween(
      begin: deviceWidth! * 0.7,
      end: 50.0,
    ).animate(
      CurvedAnimation(
        parent: buttonController,
        curve: const Interval(
          0.0,
          0.150,
        ),
      ),
    );
  }

  void searchQueryTextControllerListener() {
    waitForNextSearchRequestTimer?.cancel();
    setWaitForNextSearchRequestTimer();
  }

  void setWaitForNextSearchRequestTimer() {
    if (waitForNextRequestSearchQueryTimeInMilliSeconds != 400) {
      waitForNextRequestSearchQueryTimeInMilliSeconds = 400;
    }
    waitForNextSearchRequestTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (waitForNextRequestSearchQueryTimeInMilliSeconds == 0) {
        timer.cancel();
        if (searchQueryTextEditingController.text.trim().isNotEmpty) {
          context.read<SearchAdminCubit>().searchAdmin(
                search: searchQueryTextEditingController.text.trim(),
              );
        }
      } else {
        waitForNextRequestSearchQueryTimeInMilliSeconds =
            waitForNextRequestSearchQueryTimeInMilliSeconds - 100;
      }
    });
  }

  @override
  void dispose() {
    buttonController.dispose();
    waitForNextSearchRequestTimer?.cancel();
    searchQueryTextEditingController
        .removeListener(searchQueryTextControllerListener);
    searchQueryTextEditingController.dispose();

    super.dispose();
  }

  Widget _buildSearchTextField() {
    return TextField(
      controller: searchQueryTextEditingController,
      autofocus: true,
      cursorColor: Theme.of(context).colorScheme.primary,
      style: TextStyle(color: Theme.of(context).colorScheme.primary),
      decoration: InputDecoration(
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
        border: InputBorder.none,
        hintText: getTranslated(context, "SEARCH_SELLER"),
      ),
    );
  }

  Widget _buildSearchTextContainer() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          getTranslated(context, 'SEARCH_SELLER')!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16.0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
                iconSize: 26,
                color: Theme.of(context).colorScheme.primary,
                onPressed: () {
                  searchQueryTextEditingController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.clear))
          ],
          title: _buildSearchTextField(),
          elevation: 0.5,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.arrow_back_ios),
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        body: BlocBuilder<SearchAdminCubit, SearchAdminState>(
          builder: (context, state) {
            if (state is SearchAdminSuccess) {
              if (searchQueryTextEditingController.text.trim().isEmpty) {
                return _buildSearchTextContainer();
              }
              return ListView.builder(
                  itemCount: state.admins.length,
                  itemBuilder: (context, index) {
                    final admin = state.admins[index];
                    return ListTile(
                      leading: (admin.image ?? '').isEmpty
                          ? const Icon(Icons.person)
                          : SizedBox(
                              height: 25,
                              width: 25,
                              child: Image.network(admin.image!)),
                      onTap: () {
                        Navigator.of(context).pop();
                        Routes.navigateToConverstationScreen(
                            context: context,
                            personalChatHistory: PersonalChatHistory(
                                id: admin.id,
                                opponentUserId: admin.id,
                                unreadMsg: '0',
                                opponentUsername: admin.username,
                                image: admin.image),
                            isGroup: false);
                      },
                      title: Text(admin.username ?? '',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.lightBlack)),
                    );
                  });
            }

            if (state is SearchAdminFailure) {
              if (state.errorMessage.endsWith('No Internet connection')) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: NoInternetWidget(
                      onRetry: () {
                        context.read<SearchAdminCubit>().searchAdmin(
                            search:
                                searchQueryTextEditingController.text.trim());
                      },
                    ),
                  ),
                );
              }
              return Center(
                child: ErrorContainer(
                  errorMessage: state.errorMessage == 'Data not available !'
                      ? 'No admin found'
                      : state.errorMessage,
                  showBackButton: state.errorMessage != 'Data not available !',
                  onTapRetry: () {
                    context.read<SearchAdminCubit>().searchAdmin(
                        search: searchQueryTextEditingController.text.trim());
                  },
                ),
              );
            }

            if (state is SearchAdminInitial) {
              return _buildSearchTextContainer();
            }

            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ));
  }
}
