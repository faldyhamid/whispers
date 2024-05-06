import 'package:isar/isar.dart';
import 'utils.dart';


/*
CREATE TABLE `users`
(
    `Id`                 int NOT NULL AUTO_INCREMENT,
    `CreateAt`           bigint       DEFAULT NULL,
    `Username`           varchar(64)  DEFAULT NULL,
    `Avatar`              varchar(128) DEFAULT NULL,
    `LastSeen`          bigint  DEFAULT NULL,
); Maybe need to add firstName lastName after all
*/

part 'user.g.dart';

@collection
class User {
  Id get isarId => fastHash(id!);
  String? id;
  int createAt;
  int? lastSeen;
  String? firstName;
  String? lastName;
  String? imageUrl;

  User({required this.id, required this.createAt, this.firstName, this.lastName,
    this.lastSeen, this.imageUrl});

  User.fromJson(Map json)
      : id = json['Id'],
        createAt = json['CreateAt'],
        firstName = json['firstName'],
        lastName = json['lastName'],
        lastSeen = json['LastSeen'],
        imageUrl = json['imageUrl'];

  Map<String, dynamic> toJson() => {
        "Id": id,
        "CreateAt": createAt,
        "firstName": firstName,
        "lastName": lastName,
        "LastSeen": lastSeen,
        "imageUrl": imageUrl,
      };
}
