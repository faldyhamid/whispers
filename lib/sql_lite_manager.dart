import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'post.dart';
import 'user.dart';

const String DATABASE_NAME = 'whispers.db';
const String USERS_TABLE_NAME = 'users';
//const String CHANNELS_TABLE_NAME = 'channels';
//const String CHANNEL_MEMBERS_TABLE_NAME = 'channelmembers';
const String POST_TABLE_NAME = 'posts';

SqlManager sqlManager = new SqlManager();

class SqlManager {
  // for singleton
  static final SqlManager _sqlManager = SqlManager._internal();
  factory SqlManager() {
    return _sqlManager;
  }
  static Database? database;

  SqlManager._internal();

  createDatabase() async {
    String databasesPath = await getDatabasesPath();
    String dbPath = join(databasesPath, DATABASE_NAME);
    database = await openDatabase(dbPath);
  }

  closeDatabase() async {
    await database!.close();
  }

// USERS functions ***********************************
/*
CREATE TABLE `users`
(
    `Id`                 int NOT NULL AUTO_INCREMENT,
    `CreateAt`           bigint       DEFAULT NULL,
    `Username`           varchar(64)  DEFAULT NULL,
    `imageUrl`              varchar(128) DEFAULT NULL,
    `LastSeen`          bigint  DEFAULT NULL,
);
*/
  createUsersTable() async {
    await database!.execute("CREATE TABLE IF NOT EXISTS $USERS_TABLE_NAME ("
        "Id TEXT,"
        "CreateAt INTEGER,"
        "LastSeen INTEGER,"
        "firstName TEXT,"
        "lastName TEXT,"
        "imageUrl TEXT"
        ")");
  }

  Future<int> insertUser(User user) async {
    var result = await database!.insert(USERS_TABLE_NAME, user.toJson());
    return result;
  }

  Future<int> insertUserRaw(User user) async {
    var result = await database!.rawInsert(
        "INSERT INTO $USERS_TABLE_NAME (Id, CreateAt, LastSeen, firstName, lastName, imageUrl)"
            " VALUES (${user.id},${user.createAt},${user.lastSeen},${user.firstName},${user.lastName},${user.imageUrl})");
    return result;
  }

  Future<List> getUsers() async {
    var result = await database!.query(USERS_TABLE_NAME, columns: [
      "id",
      "CreateAt",
      "LastSeen",
      "firstName",
      "lastName",
      "imageUrl",
    ]);
    List<User> users = [];
    List queryRows = result.toList();
    queryRows.forEach((row) {
      users.add(User.fromJson(row));
    });

    return users;
  }

  Future<List> getUsersRaw() async {
    var result = await database!.rawQuery('SELECT * FROM $USERS_TABLE_NAME');
    return result.toList();
  }

  Future<User> getUser(String id) async {
    List<Map> results = await database!.query(USERS_TABLE_NAME,
        columns: [
          "id",
          "CreateAt",
          "LastSeen",
          "firstName",
          "lastName",
          "imageUrl",
        ],
        where: 'id = ?',
        whereArgs: [id]);

    if (results.isNotEmpty) {
      return User.fromJson(results.first);
    }
    throw "Exception";
  }

  Future<User> getUserRaw(String id) async {
    var results = await database!
        .rawQuery('SELECT * FROM $USERS_TABLE_NAME WHERE id = "$id"');

    if (results.isNotEmpty) {
      return User.fromJson(results.first);
    }
    throw "Exception";
  }

  Future<int> updateUser(User user) async {
    return await database!.update(USERS_TABLE_NAME, user.toJson(),
        where: "id = ?", whereArgs: [user.id]);
  }

  Future<int> updateUserRaw(User user) async {
    return await database!.rawUpdate('UPDATE $USERS_TABLE_NAME SET ' +
        'FirstName = ${user.firstName}, ' +
        'lastName = ${user.lastName}, ' +
        'imageUrl = ${user.imageUrl}, ' +
        'WHERE id = ${user.id}');
  }

  Future<void> dropUsersTable() async {
    await database!.execute('DROP TABLE IF EXISTS $USERS_TABLE_NAME');
  }
//**************************** USERS functions END
/*
// CHANNELS functions ***********************************
/*
CREATE TABLE `channels`
(
    `Id`            int NOT NULL AUTO_INCREMENT,
    `CreateAt`      bigint       DEFAULT NULL,
    `UpdateAt`      bigint       DEFAULT NULL,
    `Name`          varchar(64)  DEFAULT NULL,
    `Purpose`       varchar(250) DEFAULT NULL,
    `LastPostAt`    bigint       DEFAULT NULL,
    `CreatorId`     varchar(26)  DEFAULT NULL,
);
*/

  createChannelsTable() async {
    await database.execute("CREATE TABLE IF NOT EXISTS $CHANNELS_TABLE_NAME ("
        "Id INTEGER,"
        "CreateAt INTEGER,"
        "UpdateAt INTEGER,"
        "Name TEXT,"
        "Purpose TEXT,"
        "LastPostAt INTEGER,"
        "CreatorId INTEGER"
        ")");
  }

  Future<int> insertChannel(Channel channel) async {
    var result = await database.insert(CHANNELS_TABLE_NAME, channel.toJson());
    return result;
  }

  Future<List> getChannels() async {
    var result = await database.query(CHANNELS_TABLE_NAME, columns: [
      "Id",
      "CreateAt",
      "UpdateAt",
      "Name",
      "Purpose",
      "LastPostAt",
      "CreatorId"
    ]);
    List<Channel> channels = List();
    List queryRows = result.toList();
    queryRows.forEach((row) {
      channels.add(Channel.fromJson(row));
    });
    return channels;
  }

  Future<Channel> getChannel(int id) async {
    var results = await database
        .rawQuery('SELECT * FROM $CHANNELS_TABLE_NAME WHERE Id = $id');

    if (results.length > 0) {
      return new Channel.fromJson(results.first);
    }
    return null;
  }

  Future<int> updateChannel(Channel channel) async {
    return await database.update(CHANNELS_TABLE_NAME, channel.toJson(),
        where: "Id = ?", whereArgs: [channel.id]);
  }

  Future<void> dropChannelsTable() async {
    await database.execute('DROP TABLE IF EXISTS $CHANNELS_TABLE_NAME');
  }
//**************************** CHANNELS functions END

// CHANNEL_MEMBERS functions ***********************************
/*
CREATE TABLE `channelmembers`
(
    `ChannelId`    varchar(26) NOT NULL,
    `UserId`       varchar(26) NOT NULL,
    `Roles`        varchar(64) DEFAULT NULL,
    `LastViewedAt` bigint      DEFAULT NULL,
    `LastUpdateAt` bigint      DEFAULT NULL,
);
*/

  createChannelMembersTable() async {
    await database
        .execute("CREATE TABLE IF NOT EXISTS $CHANNEL_MEMBERS_TABLE_NAME ("
        "ChannelId INTEGER,"
        "UserId INTEGER,"
        "Roles TEXT,"
        "LastViewedAt INTEGER,"
        "LastUpdateAt INTEGER"
        ")");
  }

  Future<int> insertChannelMembers(ChannelMember channelMember) async {
    var result = await database.insert(
        CHANNEL_MEMBERS_TABLE_NAME, channelMember.toJson());
    return result;
  }

  //  all members
  Future<List> getChannelMembers() async {
    var result = await database.query(CHANNEL_MEMBERS_TABLE_NAME, columns: [
      "ChannelId",
      "UserId",
      "Roles",
      "LastViewedAt",
      "LastUpdateAt"
    ]);
    List<ChannelMember> channelMember = List();
    List queryRows = result.toList();
    queryRows.forEach((row) {
      channelMember.add(ChannelMember.fromJson(row));
    });
    return channelMember;
  }

  Future<ChannelMember> getChannelMember(int userId, int channelId) async {
    var results = await database.rawQuery(
        'SELECT * FROM $CHANNEL_MEMBERS_TABLE_NAME WHERE UserId = $userId AND ChannelId = $channelId');

    if (results.length > 0) {
      return new ChannelMember.fromJson(results.first);
    }
    return null;
  }

  Future<int> updateChannelMember(ChannelMember channelMember) async {
    return await database.update(
        CHANNEL_MEMBERS_TABLE_NAME, channelMember.toJson(),
        where: "ChannelId = ? AND UserId = ?",
        whereArgs: [channelMember.channelId, channelMember.userId]);
  }

  Future<void> dropChannelMembersTable() async {
    await database.execute('DROP TABLE IF EXISTS $CHANNEL_MEMBERS_TABLE_NAME');
  }

//**************************** CHANNEL_MEMBERS functions END
*/*/*/

// POST functions ***********************************
/*
CREATE TABLE `posts`
(
    `Id`           int NOT NULL AUTO_INCREMENT,
    `CreateAt`     bigint       DEFAULT NULL,
    'Schedule'      bigint      DEFAULT NULL
    `UserId`       int  NOT NULL,
    `Sender`          Text         NOT NULL,
    `Message`      text,
);
*/

  createPostTable() async {
    await database!.execute("CREATE TABLE IF NOT EXISTS $POST_TABLE_NAME ("
        "PostId INTEGER AUTO INCREMENT PRIMARY KEY,"
        "Id TEXT,"
        "CreateAt INTEGER,"
        "Schedule INTEGER,"
        "UserId STRING,"
        "Status INTEGER"
        "Sender TEXT,"
        "Message TEXT,"
        "Type TEXT,"
        "Uri TEXT,"
        "Payload TEXT"
        ")");
  }

  Future<int> insertPost(Post post) async {
    var result = await database!.insert(POST_TABLE_NAME, post.toJson());
    return result;
  }

  //  all members
  Future<List> getPosts() async {
    var result = await database!.rawQuery(
      'SELECT Id, UserId, Payload FROM $POST_TABLE_NAME');

    List<Post> posts = [];
    List queryRows = result.toList();
    queryRows.forEach((row) {
      posts.add(Post.fromJson(row));
    });
    return posts;
  }

  Future<List> getPost(String userId) async {
    var results = await database!.rawQuery(
        "SELECT * FROM $POST_TABLE_NAME WHERE UserId = '$userId' ORDER BY CreateAt DESC");

    List<Post> posts = [];
    List queryRows = results.toList();
    queryRows.forEach((row) {
      posts.add(Post.fromJson(row));
    });
    return posts;
  }

  Future<int> updatePost(Post post) async {
    return await database!.update(POST_TABLE_NAME, post.toJson(),
        where: "Id = ?", whereArgs: [post.id]);
  }

  Future<void> dropPostTable() async {
    await database!.execute('DROP TABLE IF EXISTS $POST_TABLE_NAME');
  }

//**************************** POST functions END
}