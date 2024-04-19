import '../Helper/String.dart';
import 'Section_Model.dart';

class FlashSaleModel {
  String? id;
  String? title;
  String? slug;
  String? shortDescription;
  String? discount;
  String? productIds;
  String? serverTime;
  String? startDate;
  String? endDate;
  String? status;
  String? image;
  Products? products;

  int? timeDiff;

  FlashSaleModel(
      {this.id,
      this.title,
      this.slug,
      this.shortDescription,
      this.discount,
      this.productIds,
      this.serverTime,
      this.startDate,
      this.endDate,
      this.status,
      this.products,
      this.image,

      this.timeDiff});

  factory FlashSaleModel.fromJson(Map<String, dynamic> parsedJson) {

    return FlashSaleModel(
        id: parsedJson[ID],
        title: parsedJson[TITLE],
        slug: parsedJson[SLUG],
        shortDescription: parsedJson[SHORT_DESC],
        discount: parsedJson[DISCOUNT],
        productIds: parsedJson[PRODUCT_IDS],
        serverTime: parsedJson[SERVER_TIME],
        startDate: parsedJson[START_DATE],
        endDate: parsedJson[END_DATE],
        status: parsedJson[STATUS],
        image: parsedJson[IMAGE_SRC],
        products: parsedJson[PRODUCTS] != null
            ? Products.fromJson(parsedJson[PRODUCTS])
            : null,

        timeDiff: 0);
  }
}

class Products {
  String? total;
  String? minPrice;
  String? maxPrice;
  List<Product>? product;
  List<Filter>? filters;

  Products(
      {this.total, this.minPrice, this.maxPrice, this.product, this.filters});

  factory Products.fromJson(Map<String, dynamic> parsedJson) {
    List<Product> productList = (parsedJson[PRODUCT] as List)
        .map((data) => Product.fromJson(data))
        .toList();

    var flist = (parsedJson[FILTERS] as List);
    List<Filter> filterList = [];
    if (flist.isEmpty) {
      filterList = [];
    } else {
      filterList = flist.map((data) => Filter.fromJson(data)).toList();
    }
    return Products(
      total: parsedJson[TOTAL],
      minPrice: parsedJson[MINPRICE],
      maxPrice: parsedJson[MAXPRICE],
      product: productList,
      filters: filterList,
    );
  }
}
