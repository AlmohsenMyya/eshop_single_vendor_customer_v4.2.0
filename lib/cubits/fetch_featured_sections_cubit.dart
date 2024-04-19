import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../Helper/String.dart';
import '../Model/Section_Model.dart';
import '../Screen/HomePage.dart';

abstract class FetchFeaturedSectionsState {}

class FetchFeaturedSectionsInitial extends FetchFeaturedSectionsState {}

class FetchFeaturedSectionsInProgress extends FetchFeaturedSectionsState {}

class FetchFeaturedSectionsSuccess extends FetchFeaturedSectionsState {
  final List<SectionModel> sectionList;
  FetchFeaturedSectionsSuccess(this.sectionList);
}

class FetchFeaturedSectionsFail extends FetchFeaturedSectionsState {
  final dynamic error;
  FetchFeaturedSectionsFail(this.error);
}

class FetchFeaturedSectionsCubit extends Cubit<FetchFeaturedSectionsState> {
  FetchFeaturedSectionsCubit() : super(FetchFeaturedSectionsInitial());

  fetchSections(BuildContext context,
      {String? pincodeOrCityName,
      String? userId,
      required bool isCityWiseDelivery}) async {
    Map<String, dynamic> parameters = {
      "p_limit": "6",
      "p_offset": "0",
    };
    try {
      emit(FetchFeaturedSectionsInProgress());
      if (userId != "" && userId != null) {
        parameters[USER_ID] = userId;
      }
      if (pincodeOrCityName != null && pincodeOrCityName.isNotEmpty) {
        if (isCityWiseDelivery) {
          parameters["city"] = pincodeOrCityName;
        } else {
          parameters[ZIPCODE] = pincodeOrCityName;
        }
      }
      var response = await apiBaseHelper.postAPICall(getSectionApi, parameters);
      hasError(response);
      var data = response["data"];
      List<SectionModel> sectionList =
          (data as List).map((data) => SectionModel.fromJson(data)).toList();
      emit(FetchFeaturedSectionsSuccess(sectionList));
    } catch (e) {
      emit(FetchFeaturedSectionsFail(e));
    }
  }

  List<SectionModel> getFeaturedSections() {
    if (state is FetchFeaturedSectionsSuccess) {
      return (state as FetchFeaturedSectionsSuccess).sectionList;
    }
    return [];
  }

  hasError(dynamic response) {
    if (response['error']) {
      emit(FetchFeaturedSectionsFail(response['message']));
    }
  }
}
