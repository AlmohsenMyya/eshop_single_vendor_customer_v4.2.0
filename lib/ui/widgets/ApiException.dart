class ApiMessageAndCodeException implements Exception {
  final String errorMessage;
  String? errorStatusCode;

  ApiMessageAndCodeException(
      {required this.errorMessage, this.errorStatusCode});

  Map toError() => {"message": errorMessage, "code": errorStatusCode};

  @override
  String toString() => errorMessage;
}

class ApiException implements Exception {
  String errorMessage;

  ApiException(this.errorMessage);

  @override
  String toString() {
    return errorMessage;
  }
}