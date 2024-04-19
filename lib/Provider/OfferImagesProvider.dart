import 'package:flutter/cupertino.dart';

import '../Model/OfferImages.dart';

class OfferImagesProvider extends ChangeNotifier {
  List<SliderImages> offerList = [];
  int selectIndex = 0;
  int offerIndex = 0;

  get curSlider => selectIndex;

  get curOfferIndex => offerIndex;

  setCurSlider(int pos) {
    selectIndex = pos;
    notifyListeners();
  }

  setOfferCurSlider(int pos) {

    offerIndex = pos;
    notifyListeners();
  }

  removeOfferList() {
    offerList.clear();
    notifyListeners();
  }

  setOfferList(List<SliderImages> offerImagesList) {
    offerList = offerImagesList;
    notifyListeners();
  }
}
