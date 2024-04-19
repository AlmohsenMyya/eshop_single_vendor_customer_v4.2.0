import 'package:flutter/cupertino.dart';

class PaymentIdProvider with ChangeNotifier {
  String? _paymentId;

  String? get paymentId => _paymentId;

  void setPaymentId(String paymentId) {
    _paymentId = paymentId;
    notifyListeners();
  }
}