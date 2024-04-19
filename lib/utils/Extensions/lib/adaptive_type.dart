class Adapter {
  ///String to int
  static int? forceInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value == "") {
      return 0;
    }
    if (value is int) {
      return value;
    } else {
      try {
        return int.tryParse(value as String);
      } catch (e) {
        throw "$value is not valid parsable int";
      }
    }
  }

  double? forceDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value == "") {
      return 0.0;
    }
    if (value is double) {
      return value;
    } else {
      try {
        return double.tryParse(value as String);
      } catch (e) {
        throw "$value is not valid parsable double";
      }
    }
  }
}
