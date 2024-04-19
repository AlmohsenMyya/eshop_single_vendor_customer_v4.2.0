import 'package:eshop/Helper/String.dart';
import 'package:intl/intl.dart';

class NotificationModel {
  String? id, title, desc, img, typeId, date, type, urlLink;

  NotificationModel(
      {this.id, this.title, this.desc, this.img, this.typeId, this.date, this.type, this.urlLink});

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    String date = json[DATE];

    date = DateFormat('dd-MM-yyyy').format(DateTime.parse(date));
    return NotificationModel(
        id: json[ID],
        title: json[TITLE],
        desc: json[MESSAGE],
        img: json[IMAGE],
        typeId: json[TYPE_ID],
        type: json[TYPE],
        urlLink: json[LINK],
        date: date);
  }
}
