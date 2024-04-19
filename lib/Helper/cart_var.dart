import 'dart:io';

import '../Model/Section_Model.dart';
import '../Model/User.dart';

List<User> addressList = [];
List<Promo> promoList = [];
double totalPrice = 0, oriPrice = 0, delCharge = 0, taxPer = 0;
int? selectedAddress = 0;
String? selAddress, payMethod = '', selTime, selDate, promocode;
bool? isTimeSlot,
    isPromoValid = false,
    isUseWallet = false,
    isPayLayShow = true;
int? selectedTime, selectedDate, selectedMethod;
bool isPromoLen = false;

double promoAmt = 0;
double remWalBal = 0, usedBal = 0;
List<File> prescriptionImages = [];

String? midtransPaymentMode,
    midtransPaymentMethod,
    midtrashClientKey,
    midTranshMerchandId,
    midtransServerKey;

String? myfatoorahToken,
    myfatoorahPaymentMode,
    myfatoorahSuccessUrl,
    myfatoorahErrorUrl,
    myfatoorahLanguage,
    myfatoorahCountry;

String? razorpayId,
    paystackId,
    stripeId,
    stripeSecret,
    stripeMode = "test",
    stripeCurCode,
    stripePayId,
    paytmMerId,
    paytmMerKey,
    phonePeMode,
    phonePeMerId,
    phonePeAppId;
bool payTesting = true;
List<SectionModel> saveLaterList = [];
String isStorePickUp = "false";
double codDeliverChargesOfShipRocket = 0.0,
    prePaidDeliverChargesOfShipRocket = 0.0;
bool? isLocalDelCharge;

String shipRocketDeliverableDate = '';
