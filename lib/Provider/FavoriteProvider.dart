import 'package:eshop/Model/Section_Model.dart';
import 'package:flutter/cupertino.dart';

class FavoriteProvider extends ChangeNotifier {
  final List<Product> _favList = [];


  bool _isLoading = true;

  get isLoading => _isLoading;

  get favList => _favList;

  get favIdList => _favList.map((fav) => fav.id).toList();



  setLoading(bool isloading) {
    _isLoading = isloading;
    notifyListeners();
  }

  removeFavItem(String id) {
    _favList.removeWhere((item) => item.prVarientList![0].id == id);


    notifyListeners();
  }

  addFavItem(Product? item) {
    if (item != null) {
      _favList.add(item);
      notifyListeners();
    }
  }

  setFavlist(List<Product> favList) {
    _favList.clear();
    _favList.addAll(favList);
    notifyListeners();
  }


}
