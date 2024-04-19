import 'package:intl_phone_field/phone_number.dart';

String? validateUserName(String value, String? msg1, String? msg2) {
  if (value.isEmpty) {
    return msg1;
  }
  if (value.length <= 1) {
    return msg2;
  }
  return null;
}

String? validateMobIntl(PhoneNumber? phoneNumber, String? msg1, String? msg2) {
  if (phoneNumber == null || phoneNumber.number.isEmpty) {
    return msg1;
  }
  if (phoneNumber.number.length < 6 || phoneNumber.number.length > 15) {
    return msg2;
  }
  return null;
}

String? validateMob(String value, String? msg1, String? msg2, {bool? check}) {
  if (check == null) {
    if (value.isEmpty) {
      return msg1;
    }
    if (value.length < 6 || value.length > 15) {
      return msg2;
    }
  } else {
    if (value.isNotEmpty && value.length < 6 || value.length > 15) {
      return msg2;
    }
  }
  return null;
}

String? validateCountryCode(String value, String msg1, String msg2) {
  if (value.isEmpty) {
    return msg1;
  }
  if (value.isEmpty) {
    return msg2;
  }
  return null;
}

String? validatePass(String value, String? msg1, String? msg2, {int? from}) {
  if (value.isEmpty) {
    return msg1;
  } else if (from == null &&
      !RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$')
          .hasMatch(value)) {
    return msg2;
  } else {
    return null;
  }
}

/*String? validatePass(String value, String? msg1, String? msg2) {
  if (value.isEmpty) {
    return msg1;
  } else if (value.length <= 5) {
    return msg2;
  } else {
    return null;
  }
}*/

String? validateAltMob(String value, String? msg) {
  if (value.isNotEmpty && value.length < 6 || value.length > 15) {
    return msg;
  }
  return null;
}

String? validateField(String value, String? msg) {
  if (value.isEmpty) {
    return msg;
  } else {
    return null;
  }
}

String? validatePincode(String value, String? msg1) {
  if (value.isEmpty) {
    return msg1;
  } else {
    return null;
  }
}

String? validateEmail(String value, String? msg1, String? msg2) {
  if (value.isEmpty) {
    return msg1;
  } else if (!RegExp(
          r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)"
          r"*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+"
          r"[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
      .hasMatch(value)) {
    return msg2;
  } else {
    return null;
  }
}
