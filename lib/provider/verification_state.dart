import 'package:flutter/material.dart';

class PaymentProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isPaymentDone = false;

  bool get isLoading => _isLoading;
  bool get isPaymentDone => _isPaymentDone;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setPayment(bool val) {
    _isPaymentDone = true;
    notifyListeners();
  }
}
