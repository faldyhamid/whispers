import 'package:isar/isar.dart';
import 'utils.dart';


/*
CREATE TABLE `posts`
(
    `Id`           int NOT NULL AUTO_INCREMENT,
    `CreateAt`     bigint       DEFAULT NULL,
    'Schedule'      bigint      DEFAULT NULL
    `UserId`       varchar(26)  DEFAULT NULL,
    `side`          int         NOT NULL,
    `type`          text
    `Status`       text,
    `Message`      text,
);
*/

part 'post.g.dart';

@collection
class Post {
  Id get isarId => fastHash(id!);
  String? id;
  int? createAt;
  int? schedule;
  @Index()
  int? userId;
  int? status; //delivered, seen, 0 no (if scheduled)
  String? message;
  String? payload;

  Post({this.id, this.createAt, this.schedule, this.userId,  this.status, this.message, this.payload});

  Post.fromJson(Map json)
      : id = json['Id'],
        createAt = json['CreateAt'],
        schedule = json['Schedule'],
        userId = json['UserId'],
        status = json['Status'],
        message = json['Message'],
        payload = json['Payload'];


  Map<String, dynamic> toJson() => {
        "Id": id,
        "CreateAt": createAt,
        "Schedule": schedule,
        "UserId": userId,
        "Status": status,
        "Message": message,
        "Payload": payload
      };
}
