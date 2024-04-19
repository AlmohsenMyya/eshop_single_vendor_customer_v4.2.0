import 'package:eshop/Helper/String.dart';
import 'package:intl/intl.dart';

class User {
  String? username,
      userProfile,
      email,
      mobile,
      address,
      dob,
      city,
      area,
      street,
      password,
      pincode,
      fcmId,
      latitude,
      longitude,
      userId,
      name,
      deliveryCharge,
      freeAmt,
      zipcode;

  List<String>? imgList;
  String? id, date, comment, rating;

  String? type, altMob, landmark, cityId, isDefault, state, country, systemZipcode;

  User(
      {this.id,
      this.username,
      this.userProfile,
      this.date,
      this.rating,
      this.comment,
      this.email,
      this.mobile,
      this.address,
      this.dob,
      this.city,
      this.area,
      this.street,
      this.password,
      this.pincode,
      this.fcmId,
      this.latitude,
      this.longitude,
      this.userId,
      this.name,
      this.type,
      this.altMob,
      this.landmark,
      this.systemZipcode,
      this.cityId,
      this.imgList,
      this.isDefault,
      this.state,
      this.deliveryCharge,
      this.freeAmt,
      this.country,
      this.zipcode});

  factory User.forReview(Map<String, dynamic> parsedJson) {
    String date = parsedJson['data_added'];
    var allSttus = parsedJson['images'];
    List<String> item = [];

    for (String i in allSttus) {
      item.add(i);
    }

    date = DateFormat('dd-MM-yyyy').format(DateTime.parse(date));

    return User(
        id: parsedJson[ID],
        date: date,
        rating: parsedJson[RATING],
        comment: parsedJson[COMMENT],
        imgList: item,
        username: parsedJson[USER_NAME],
        userProfile: parsedJson["user_profile"],
        userId: parsedJson["user_id"]);
  }

  factory User.fromJson(Map<String, dynamic> parsedJson) {
    return User(
      id: parsedJson[ID],
      username: parsedJson[USERNAME],
      email: parsedJson[EMAIL],
      mobile: parsedJson[MOBILE],
      address: parsedJson[ADDRESS],
      city: parsedJson[CITY],
      area: parsedJson[AREA],
      pincode: parsedJson["pincode"],
      zipcode: parsedJson[ZIPCODE],
      fcmId: parsedJson[FCM_ID],
      latitude: parsedJson[LATITUDE],
      longitude: parsedJson[LONGITUDE],
      userId: parsedJson[USER_ID],
      name: parsedJson[NAME],

    );
  }

  factory User.fromAddress(Map<String, dynamic> parsedJson) {
    return User(
        id: parsedJson[ID],
        mobile: parsedJson[MOBILE],
        address: parsedJson[ADDRESS],
        altMob: parsedJson[ALT_MOBNO],
        cityId: parsedJson[CITY_ID],

        area: parsedJson[AREA],
        city: parsedJson[CITY],
        landmark: parsedJson[LANDMARK],
        state: parsedJson[STATE],
        pincode: parsedJson["pincode"],
        country: parsedJson[COUNTRY],
        latitude: parsedJson[LATITUDE],
        longitude: parsedJson[LONGITUDE],
        userId: parsedJson[USER_ID],
        name: parsedJson[NAME],
        type: parsedJson[TYPE],
        deliveryCharge: parsedJson[DEL_CHARGES],
        freeAmt: parsedJson[FREE_AMT],
        systemZipcode: parsedJson[SYSTEM_PINCODE] ,

        isDefault: parsedJson[ISDEFAULT]);
  }
}

class imgModel {
  int? index;
  String? img;

  imgModel({this.index, this.img});

  factory imgModel.fromJson(int i, String image) {
    return imgModel(index: i, img: image);
  }
}
