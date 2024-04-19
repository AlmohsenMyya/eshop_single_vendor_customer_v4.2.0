import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart' as dio_;
import 'package:eshop/ui/widgets/ApiException.dart';
import 'package:http/http.dart';

import 'Constant.dart';
import 'Session.dart';

class ApiBaseHelper {
  final dio_.Dio dio = dio_.Dio();

  Future<void> downloadFile(
      {required String url,
      required dio_.CancelToken cancelToken,
      required String savePath,
      required Function updateDownloadedPercentage}) async {
    try {
      final dio_.Dio dio = dio_.Dio();
      await dio.download(url, savePath, cancelToken: cancelToken,
          onReceiveProgress: ((count, total) {
        updateDownloadedPercentage((count / total) * 100);
      }));
    } on dio_.DioException catch (e) {
      if (e.type == dio_.DioExceptionType.connectionError) {
        throw ApiException('No Internet connection');
      }

      throw ApiException('Failed to download file');
    } catch (e) {
      throw Exception('Failed to download file');
    }
  }

  Future<dynamic> postAPICall(Uri url, Map param) async {
    var responseJson;
    try {
      final response = await post(url,
              body: param.isNotEmpty ? param : null, headers: headers)
          .timeout(const Duration(seconds: timeOut));
      print("param****$param****$url");
      print("respon****${response.statusCode}");

      responseJson = _response(response);

      log("responjson** ${url} $param ----**$responseJson");
    } on SocketException {
      throw FetchDataException('No Internet connection');
    } on TimeoutException {
      throw FetchDataException('Something went wrong, try again later');
    }

    return responseJson;
  }

  dynamic _response(Response response) {
    switch (response.statusCode) {
      case 200:
        print("Reponse is ${getToken()}");
        var responseJson = json.decode(response.body.toString());
        return responseJson;
      case 400:
        throw BadRequestException(response.body.toString());
      case 401:
      case 403:
        throw UnauthorisedException(response.body.toString());
      case 500:
      default:
        throw FetchDataException(
            'Error occurred while Communication with Server with StatusCode: ${response.statusCode}');
    }
  }

  // Future<Map<String, dynamic>> postAPICall(Uri url, Map param) async {
  //   var responseJson;
  //   dio_.Response? response;
  //   try {
  //     try {
  //       print("param****$param ****$url $headers");
  //       response = await dio
  //           .post(url.toString(),
  //               data: {
  //                     "user_id": 1,
  //                     "username": "admin",
  //                     "email": "wrteam.demo@gmail.com",
  //                     "mobile": "9876543210"
  //                   } ??
  //                   (param.isNotEmpty ? param : null),
  //               options: dio_.Options(
  //                   headers: Map.from(headers),
  //                   contentType: "application/json"))
  //           .timeout(const Duration(seconds: timeOut));
  //     } catch (e) {
  //       log("SELF ERROR THROWING ${e}");
  //       rethrow;
  //     }
  //     print("param****$param ****$url $headers");
  //     print("respon****${response.statusCode}");
  //
  //     responseJson = _response(response);
  //
  //     print(
  //         "responjson ${response.requestOptions.uri.toString()}****$responseJson");
  //   } on SocketException {
  //     throw FetchDataException('No Internet connection');
  //   } on TimeoutException {
  //     throw FetchDataException('Something went wrong, try again later');
  //   } on dio_.DioException catch (e, st) {
  //     print("ERROR IN DIO WHILE UPLOAD iMAGE ${e.requestOptions.data}");
  //     throw Exception({"error": true, "message": "NO message"});
  //   }
  //
  //   return responseJson ?? {};
  // }
  //
  // dynamic _response(dio_.Response response) {
  //   try {
  //     switch (response.statusCode) {
  //       case 200:
  //         var responseJson = response.data;
  //         return responseJson;
  //       case 400:
  //         throw BadRequestException(response.data.toString());
  //       case 401:
  //       case 403:
  //         throw UnauthorisedException(response.data.toString());
  //       case 500:
  //       default:
  //         throw FetchDataException(
  //             'Error occurred while Communication with Server with StatusCode: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     log("ERROR WHILE SHARE RESPONSE $e");
  //   }
  // }
}

class CustomException implements Exception {
  final _message;
  final _prefix;

  CustomException([this._message, this._prefix]);

  @override
  String toString() {
    return "$_prefix$_message";
  }
}

class FetchDataException extends CustomException {
  FetchDataException([message])
      : super(message, "Error During Communication: ");
}

class BadRequestException extends CustomException {
  BadRequestException([message]) : super(message, "Invalid Request: ");
}

class UnauthorisedException extends CustomException {
  UnauthorisedException([message]) : super(message, "Unauthorised: ");
}

class InvalidInputException extends CustomException {
  InvalidInputException([message]) : super(message, "Invalid Input: ");
}
