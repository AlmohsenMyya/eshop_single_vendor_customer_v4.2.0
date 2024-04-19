import 'package:eshop/Helper/String.dart';
import 'package:eshop/Model/User.dart';

class SectionModel {
  String? id,
      title,
      varientId,
      qty,
      productId,
      perItemTotal,
      perItemPrice,
      style,
      shortDesc,
      taxPercentage,
      taxAmt,
      netAmt;

  List<Product>? productList;
  List<Filter>? filterList;
  List<String>? selectedId = [];
  int? offset, totalItem;

  SectionModel({
    this.id,
    this.title,
    this.productList,
    this.varientId,
    this.qty,
    this.productId,
    this.perItemTotal,
    this.perItemPrice,
    this.style,
    this.totalItem,
    this.offset,
    this.selectedId,
    this.filterList,
    this.shortDesc,
    this.netAmt,
    this.taxAmt,
    this.taxPercentage,
  });

  factory SectionModel.fromJson(Map<String, dynamic> parsedJson) {
    List<Product> productList = (parsedJson[PRODUCT_DETAIL] as List)
        .map((data) => Product.fromJson(data))
        .toList();

    var flist = (parsedJson[FILTERS] as List);
    List<Filter> filterList = [];
    if (flist.isEmpty) {
      filterList = [];
    } else {
      filterList = flist.map((data) => Filter.fromJson(data)).toList();
    }
    List<String> selected = [];
    return SectionModel(
      id: parsedJson[ID],
      title: parsedJson[TITLE],
      style: parsedJson[STYLE],
      productList: productList,
      offset: 0,
      totalItem: 0,
      filterList: filterList,
      shortDesc: parsedJson[SHORT_DESC],
      selectedId: selected,
    );
  }

  factory SectionModel.fromCart(Map<String, dynamic> parsedJson) {
    List<Product> productList = (parsedJson[PRODUCT_DETAIL] as List)
        .map((data) => Product.fromJson(data))
        .toList();

    return SectionModel(
        id: parsedJson[ID],
        varientId: parsedJson[PRODUCT_VARIENT_ID],
        qty: parsedJson[QTY],
        perItemTotal: "0",
        perItemPrice: "0",
        productList: productList,
        netAmt: parsedJson[NET_AMOUNT].toString(),
        taxAmt: parsedJson[TAX_AMT].toString(),
        taxPercentage: parsedJson[TAX_PER].toString());
  }

  factory SectionModel.fromFav(Map<String, dynamic> parsedJson) {
    List<Product> productList = (parsedJson[PRODUCT_DETAIL] as List)
        .map((data) => Product.fromJson(data))
        .toList();

    return SectionModel(
        id: parsedJson[ID],
        productId: parsedJson[PRODUCT_ID],
        productList: productList);
  }
}

class Product {
  String? id,
      name,
      desc,
      image,
      catName,
      type,
      rating,
      noOfRating,
      attrIds,
      tax,
      categoryId,
      shortDescription,
      qtyStepSize,
      calDisPer,
      productType;
  List<String>? itemsCounter;
  List<String>? otherImage;
  List<Product_Varient>? prVarientList;
  List<Attribute>? attributeList;
  List<String>? selectedId = [];
  List<String>? tagList = [];
  int? minOrderQuntity;

  String? isFav,
      isReturnable,
      isCancelable,
      isPurchased,
      availability,
      madein,
      indicator,
      stockType,
      cancleTill,
      banner,
      totalAllow,
      video,
      videType,
      warranty,
      gurantee,
      codAllowed,
      is_attch_req,
      isSalesOn,
      saleDis,
      brand,
      total,
      saleStartDate,
      saleEndDate,
      serverTime;
  int? timeDiff;

  String? totalImg;
  List<ReviewImg>? reviewList;

  bool? isFavLoading = false, isFromProd = false;
  int? offset, totalItem, selVarient;

  List<Product>? subList;
  List<Filter>? filterList;
  bool? history = false;

  Product(
      {this.id,
      this.name,
      this.desc,
      this.image,
      this.catName,
      this.type,
      this.otherImage,
      this.prVarientList,
      this.attributeList,
      this.isFav,
      this.isCancelable,
      this.isReturnable,
      this.isPurchased,
      this.availability,
      this.noOfRating,
      this.attrIds,
      this.selectedId,
      this.rating,
      this.isFavLoading,
      this.indicator,
      this.madein,
      this.tax,
      this.shortDescription,
      this.total,
      this.categoryId,
      this.subList,
      this.filterList,
      this.stockType,
      this.isFromProd,
      this.cancleTill,
      this.totalItem,
      this.offset,
      this.totalAllow,
      this.banner,
      this.selVarient,
      this.video,
      this.videType,
      this.tagList,
      this.warranty,
      this.qtyStepSize,
      this.minOrderQuntity,
      this.itemsCounter,
      this.reviewList,
      this.history,
      this.gurantee,
      this.calDisPer,
      this.codAllowed,
      this.is_attch_req,
      this.isSalesOn,
      this.saleDis,
      this.brand,
      this.saleEndDate,
      this.saleStartDate,
      this.serverTime,
      this.timeDiff,
      this.productType});

  factory Product.fromJson(Map<String, dynamic> json) {
    var vList = (json[PRODUCT_VARIENT] as List?);
    List<Product_Varient> varientList = [];
    if (vList == null || vList.isEmpty) {
      varientList = [];
    } else {
      varientList = (json[PRODUCT_VARIENT] as List)
          .map((data) => Product_Varient.fromJson(data))
          .toList();
    }

    var atList = (json[PRODUCT_VARIENT] as List?);
    List<Attribute> attList = [];
    if (atList == null || atList.isEmpty) {
      attList = [];
    } else {
      attList = (json[ATTRIBUTES] as List)
          .map((data) => Attribute.fromJson(data))
          .toList();
    }

    var flist = (json[FILTERS] as List?);
    List<Filter> filterList = [];
    if (flist == null || flist.isEmpty) {
      filterList = [];
    } else {
      filterList = flist.map((data) => Filter.fromJson(data)).toList();
    }

    List<String> otherImage = (json[OTHER_IMAGE] as List?) == null
        ? []
        : List<String>.from(json[OTHER_IMAGE]);
    List<String> selected = [];

    List<String> tags =
        (json[TAG] as List?) == null ? [] : List<String>.from(json[TAG]);

    /*  List<String> items = [];
    print("total allow****${json[TOTALALOOW]}");
    if (json[TOTALALOOW] != "" || json[TOTALALOOW] != null) {
      items = List<String>.generate(
          json[TOTALALOOW] != "" || json[TOTALALOOW] != null
              ? double.parse(json[TOTALALOOW]) ~/ double.parse(json[QTYSTEP])
              : 10, (i) {
        return ((i + 1) * int.parse(json[QTYSTEP])).toString();
      });
    }*/

    List<String> items = List<String>.generate(
        json[TOTALALOOW] != ''
            ? double.parse(json[TOTALALOOW]) ~/ double.parse(json[QTYSTEP])
            : 10, (i) {
      return ((i + 1) * int.parse(json[QTYSTEP])).toString();
    });

    var reviewImg = (json[REV_IMG] as List?);
    List<ReviewImg> reviewList = [];
    if (reviewImg == null || reviewImg.isEmpty) {
      reviewList = [];
    } else {
      reviewList = reviewImg.map((data) => ReviewImg.fromJson(data)).toList();
    }

    return Product(
      id: json[ID],
      name: json[NAME],
      desc: json[DESC],
      image: json[IMAGE],
      catName: json[CAT_NAME],
      rating: json[RATING],
      noOfRating: json[NO_OF_RATE],
      type: json[TYPE],
      isFav: json[FAV].toString(),
      isCancelable: json[ISCANCLEABLE],
      availability: json[AVAILABILITY].toString(),
      isPurchased: json[ISPURCHASED].toString(),
      isReturnable: json[ISRETURNABLE],
      otherImage: otherImage,
      prVarientList: varientList,
      attributeList: attList,
      filterList: filterList,
      isFavLoading: false,
      selVarient: 0,
      attrIds: json[ATTR_VALUE],
      madein: json[MADEIN],
      shortDescription: json[SHORT],
      indicator: json[INDICATOR].toString(),
      stockType: json[STOCKTYPE].toString(),
      tax: json[TAX_PER],
      total: json[TOTAL],
      categoryId: json[CATID],
      selectedId: selected,
      totalAllow: json[TOTALALOOW],
      cancleTill: json[CANCLE_TILL],
      video: json[VIDEO],
      videType: json[VIDEO_TYPE],
      tagList: tags,
      itemsCounter: items,
      warranty: json[WARRANTY],
      minOrderQuntity: int.parse(json[MINORDERQTY]),
      qtyStepSize: json[QTYSTEP],
      gurantee: json[GAURANTEE],
      reviewList: reviewList,
      history: false,
      calDisPer: json[CAL_DIS_PER],
      codAllowed: json[COD_ALLOWED],
      is_attch_req: json[IS_ATTACH_REQ],
      isSalesOn: json[IS_SALES_ON],
      saleDis: json[SALE_DIS],
      brand: json[BRAND],
      saleEndDate: json[SALE_END_DATE],
      saleStartDate: json[SALE_START_DATE],
      serverTime: json[SERVER_TIME],
      timeDiff: 0,
      productType: json[TYPE],
    );
  }

  factory Product.popular(String name, String image) {
    return Product(name: name, image: image);
  }

  factory Product.history(String history) {
    return Product(name: history, history: true);
  }

  factory Product.fromCat(Map<String, dynamic> parsedJson) {
    return Product(
      id: parsedJson[ID],
      name: parsedJson[NAME],
      image: parsedJson[IMAGE],
      banner: parsedJson[BANNER],
      isFromProd: false,
      offset: 0,
      totalItem: 0,
      tax: parsedJson[TAX],
      subList: createSubList(parsedJson["children"]),
    );
  }

  static List<Product>? createSubList(List? parsedJson) {
    if (parsedJson!.isEmpty) return null;

    return parsedJson.map((data) => Product.fromCat(data)).toList();
  }

  @override
  String toString() {
    return 'Product{id: $id, name: $name, desc: $desc, image: $image, catName: $catName, type: $type, rating: $rating, noOfRating: $noOfRating, attrIds: $attrIds, tax: $tax, categoryId: $categoryId, shortDescription: $shortDescription, qtyStepSize: $qtyStepSize, calDisPer: $calDisPer, productType: $productType, itemsCounter: $itemsCounter, otherImage: $otherImage, prVarientList: $prVarientList, attributeList: $attributeList, selectedId: $selectedId, tagList: $tagList, minOrderQuntity: $minOrderQuntity, isFav: $isFav, isReturnable: $isReturnable, isCancelable: $isCancelable, isPurchased: $isPurchased, availability: $availability, madein: $madein, indicator: $indicator, stockType: $stockType, cancleTill: $cancleTill, banner: $banner, totalAllow: $totalAllow, video: $video, videType: $videType, warranty: $warranty, gurantee: $gurantee, codAllowed: $codAllowed, is_attch_req: $is_attch_req, isSalesOn: $isSalesOn, saleDis: $saleDis, brand: $brand, total: $total, saleStartDate: $saleStartDate, saleEndDate: $saleEndDate, serverTime: $serverTime, timeDiff: $timeDiff, totalImg: $totalImg, reviewList: $reviewList, isFavLoading: $isFavLoading, isFromProd: $isFromProd, offset: $offset, totalItem: $totalItem, selVarient: $selVarient, subList: $subList, filterList: $filterList, history: $history}';
  }
}

class Product_Varient {
  String? id,
      productId,
      attribute_value_ids,
      price,
      disPrice,
      type,
      attr_name,
      varient_value,
      availability,
      cartCount,
      saleFinalPrice;
  List<String>? images;

  Product_Varient({
    this.id,
    this.productId,
    this.attr_name,
    this.varient_value,
    this.price,
    this.disPrice,
    this.attribute_value_ids,
    this.availability,
    this.cartCount,
    this.images,
    this.saleFinalPrice,
  });

  factory Product_Varient.fromJson(Map<String, dynamic> json) {
    List<String> images = List<String>.from(json[IMAGES]);

    return Product_Varient(
        id: json[ID],
        attribute_value_ids: json[ATTRIBUTE_VALUE_ID],
        productId: json[PRODUCT_ID],
        attr_name: json[ATTR_NAME],
        varient_value: json[VARIENT_VALUE],
        disPrice: json[DIS_PRICE],
        price: json[PRICE],
        availability: json[AVAILABILITY].toString(),
        cartCount: json[CART_COUNT],
        images: images,
        saleFinalPrice: json[SALE_FINAL_PRICE]);
  }
}

class Attribute {
  String? id, value, name, sType, sValue;

  Attribute({this.id, this.value, this.name, this.sType, this.sValue});

  factory Attribute.fromJson(Map<String, dynamic> json) {
    return Attribute(
        id: json[IDS],
        name: json[NAME],
        value: json[VALUE],
        sType: json[STYPE],
        sValue: json[SVALUE]);
  }
}

class Filter {
  String? attributeValues, attributeValId, name, swatchType, swatchValue;

  Filter(
      {this.attributeValues,
      this.attributeValId,
      this.name,
      this.swatchType,
      this.swatchValue});

  factory Filter.fromJson(Map<String, dynamic> json) {
    return Filter(
        attributeValId: json[ATT_VAL_ID],
        name: json[NAME],
        attributeValues: json[ATT_VAL],
        swatchType: json[STYPE],
        swatchValue: json[SVALUE]);
  }
}

class ReviewImg {
  String? totalImg;
  List<User>? productRating;

  ReviewImg({this.totalImg, this.productRating});

  factory ReviewImg.fromJson(Map<String, dynamic> json) {
    var reviewImg = (json[PRODUCTRATING] as List);
    List<User> reviewList = [];
    if (reviewImg.isEmpty) {
      reviewList = [];
    } else {
      reviewList = reviewImg.map((data) => User.forReview(data)).toList();
    }

    return ReviewImg(totalImg: json[TOTALIMG], productRating: reviewList);
  }
}

class Promo {
  String? id,
      promoCode,
      message,
      image,
      remainingDays,
      status,
      noOfRepeatUsage,
      maxDiscountAmt,
      discountType,
      noOfUsers,
      minOrderAmt,
      repeatUsage,
      discount,
      endDate,
      startDate;
  bool isExpanded;

  Promo({
    this.id,
    this.promoCode,
    this.message,
    this.startDate,
    this.endDate,
    this.discount,
    this.repeatUsage,
    this.minOrderAmt,
    this.noOfUsers,
    this.discountType,
    this.maxDiscountAmt,
    this.image,
    this.noOfRepeatUsage,
    this.status,
    this.remainingDays,
    this.isExpanded = false,
  });

  factory Promo.fromJson(Map<String, dynamic> json) {
    return Promo(
      id: json[ID],
      promoCode: json[PROMO_CODE],
      message: json[MESSAGE],
      image: json[IMAGE],
      remainingDays: json[REMAIN_DAY],
      discount: json[DISCOUNT],
      discountType: json[DISCOUNT_TYPE],
      endDate: json[END_DATE],
      maxDiscountAmt: json[MAX_DISCOUNT_AMOUNT],
      minOrderAmt: json[MIN_ORDER_AMOUNT],
      noOfRepeatUsage: json[NO_OF_REPEAT_USAGE],
      noOfUsers: json[NO_OF_USERS],
      repeatUsage: json[REPEAT_USAGE],
      startDate: json[START_DATE],
      status: json[STATUS],
    );
  }
}
