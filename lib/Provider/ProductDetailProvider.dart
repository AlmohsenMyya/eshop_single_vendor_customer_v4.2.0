import 'package:eshop/Model/Section_Model.dart';
import 'package:flutter/cupertino.dart';

class ProductDetailProvider extends ChangeNotifier {
  final bool _reviewLoading = true;
  bool _moreProductLoading = true;
  int _offset = 0;
  int _total = 0;
  bool _moreProNotiLoading = true;
  final bool _notificationisgettingdata1 = false;
  final bool _notificationisnodata1 = false;

  final List<Product> _compareList = [];
  List<Product> _productList = [];
//  Product _productData = Product();



  get compareList => _compareList;

  get productList => _productList;

  get moreProNotiLoading => _moreProNotiLoading;

  get offset => _offset;

  get total => _total;

//  Product get productData => _productData;

  get moreProductLoading => _moreProductLoading;

  get reviewLoading => _reviewLoading;

  get notificationisgettingdata1 => _notificationisgettingdata1;

  get notificationisnodata1 => _notificationisnodata1;



  setReviewLoading(bool loading) {
    _moreProductLoading = loading;
    notifyListeners();
  }

 /* setProductData(Product model) {
    _productData = model;
    notifyListeners();
  }*/

  setProductLoading(bool loading) {
    _moreProductLoading = loading;
    notifyListeners();
  }

  setProNotiLoading(bool loading) {
    _moreProNotiLoading = loading;
    notifyListeners();
  }

  setProGetData(bool loading) {
    _moreProductLoading = loading;
    notifyListeners();
  }

  setProOffset(int offset) {
    _offset = offset;
    notifyListeners();
  }

  setProTotal(int total) {
    _total = total;
    notifyListeners();
  }

  addComFirstIndex(Product compareList) {
    _compareList.insert(0, compareList);
    notifyListeners();
  }

  addCompareList(Product compareList) {
    _compareList.add(compareList);
    notifyListeners();
  }

  removeCompareList() {
    _compareList.clear();
    _productList.clear();

    notifyListeners();
  }

  setProductList(List<Product>? productList) {
    _productList = productList!;
    notifyListeners();
  }

/*  setDiffTime(int diff, {String? isSaleOn}) {

    _productData.timeDiff = diff;
    if (isSaleOn != null) {
      _productData.isSalesOn = isSaleOn;
    }
    notifyListeners();
  }*/


}
