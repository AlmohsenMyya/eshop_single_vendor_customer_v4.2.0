import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {

  bool isProgress=false;

  String userName = '',
      cartCount = '',
      curBal = '',
      mobile = '',
      profilePicture = '',
      emailAdd = '',
      type = '';
  String userId = '';

  String? _curPincode = '';

  String get curUserName => userName;

  String get curPincode => _curPincode ?? '';

  String get curCartCount => cartCount;

  String get curBalance => curBal;

  String get mob => mobile;

  String get profilePic => profilePicture;



  String get email => emailAdd;

  String get loginType => type;
  bool get getProgress => isProgress;

  void setPincode(String pin) {
    _curPincode = pin;
    notifyListeners();
  }


  void setProgress(bool progress) {
    isProgress=progress;
    notifyListeners();
  }

  void setCartCount(String count) {
    print("count cart****$count");
    cartCount = count;
    notifyListeners();
  }
  void setBalance(String bal) {
    curBal = bal;
    notifyListeners();
  }
  void setName(String count) {
    userName = count;
    notifyListeners();
  }
  void setMobile(String count) {
    mobile = count;
    notifyListeners();
  }
  void setProfilePic(String count) {
    profilePicture = count;
    notifyListeners();
  }
  void setEmail(String email) {
    emailAdd = email;
    notifyListeners();
  }
  void setType(String typeLogin) {
    type = typeLogin;
    notifyListeners();
  }
  void setUserId(String count) {
    userId = count;
  }
}
