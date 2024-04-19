import 'dart:core';
import 'package:eshop/Helper/ApiBaseHelper.dart';
import 'package:eshop/Helper/String.dart';
import 'package:eshop/Model/searchAdmin.dart';
import 'package:eshop/ui/widgets/ApiException.dart';

class AdminDetailRepository {
  //Api to search the seller.. User can searc hthe seller and send message to seller
  Future<List<SearchedAdmin>> searchAdmin({
    required Map<String, dynamic> parameter,
  }) async {
    try {
      var result = await ApiBaseHelper().postAPICall(searchAdminApi, parameter);

      if (result['error']) {
        throw ApiException(result['message'] ?? 'Failed to get sellers');
      }

      return ((result['data'] ?? []) as List)
          .map((seller) => SearchedAdmin.fromJson(Map.from(seller ?? {})))
          .toList();
    } on Exception catch (e) {
      throw ApiException(e.toString());
    }
  }
}
