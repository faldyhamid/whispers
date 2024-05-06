import 'dart:convert';

import 'package:path/path.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import 'utils.dart';
import 'post.dart';
import 'user.dart';

const String User_Schema_Name = 'UserSchema';
const String Post_Schema_Name = 'PostSchema';

IsarManager isarManager = new IsarManager();

class IsarManager {
  // for singleton
  static final IsarManager _isarManager = IsarManager._internal();

  factory IsarManager() {
    return _isarManager;
  }

  static late Isar database;

  IsarManager._internal();

  handleIsar() async {
    if(Isar.getInstance() == null){
      final dir = await getApplicationDocumentsDirectory();

      database = await Isar.open(
        [UserSchema, PostSchema],
        directory: dir.path,
      );
    }
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

  Future<void> insertUser(User user) async {
    var result = await database.writeTxn(() async {
      database.users.put(user);
    });

    return result;
  }

  Future<List<User>> getUsers() async {
    List<User> result = await database.users.where().sortByLastSeenDesc().findAll();

    return result;
  }

  Future<User?> getUser(int id) async {
    User? result = await database.users.get(id);
    print(result);

    return result;
  }

  Future<void> updateUser(User user) async {
    var result = await database.writeTxn(() async {
      database.users.put(user);
    });

    return result;
  }

  Future<void> deleteUser(int id) async {
    await database.writeTxn(() async{
      return await database.users.delete(id);
    });
  }

  Future<void> clearUsersCollection() async {
    await database.writeTxn(() async {
      database.users.clear();
    });
  }
//**************************** USERS functions END


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

  Future<void> insertPost(Post post) async {
    var result = await database.writeTxn(() async {
      database.posts.put(post);
    });

    return result;
  }

  Future<List<Post>> getPosts() async {
    List<Post> result = await database.posts.where().findAll();

    return result;
  }

  Future<Post?> getPost(int id) async {
    Post? result = await database.posts.where()
        .isarIdEqualTo(id)
        .findFirst();

    return result;
  }

  Future<Post?> getLatestPost(int id) async {
    Post? result = await database.posts.where()
        .userIdEqualTo(id)
        .filter()
        .statusEqualTo(1)
        .sortByCreateAtDesc()
        .findFirst();

    return result;
  }

  Future<Stream<List<Post>>> getLatestPostStream() async {
    Query<Post> query = database.posts
        .filter()
        .statusEqualTo(1)
        .sortByCreateAtDesc()
        .distinctByUserId()
        .build();

    return query.watch(fireImmediately: true);
  }

  Future<Stream<void>> getScheduledBuffer(int id) async {
    Query<void> query = database.posts
        .where()
        .userIdEqualTo(id)
        .filter()
        .statusEqualTo(1)
        .sortByCreateAtDesc()
        .build();

    return query.watchLazy();
  }

  Future<List<Post>> getNewScheduledPosts(int id, int latestCreate) async {
    List<Post> result = await database.posts
        .where()
        .isarIdEqualTo(id)
        .filter()
        .statusEqualTo(1)
        .createAtGreaterThan(latestCreate)
        .sortByCreateAtDesc()
        .findAll();

    return result;
  }

  Future<void> deleteActivePost(int id) async {
    await database.posts.where()
        .userIdEqualTo(id)
        .filter()
        .statusEqualTo(1)
        .deleteAll();
  }

  Future<List> getActivePost(int id, int setOffset) async {
    List<Post> result = await database.posts.where()
        .userIdEqualTo(id)
        .filter()
        .statusEqualTo(1)
        .sortByCreateAtDesc()
        .offset(setOffset).limit(15)
        .findAll();

    return result;
  }

  Future<List> getScheduledPost(int id, int setOffset) async {
    List<Post> result = await database.posts.where()
        .userIdEqualTo(id)
        .filter()
        .statusEqualTo(0)
        .sortByCreateAtDesc()
        .offset(setOffset).limit(15)
        .findAll();

    return result;
  }

  Future<void> updatePost(Post post) async {
    var result = await database.writeTxn(() async {
      database.posts.put(post);
    });

    return result;
  }

  Future<void> updatePayload(types.Message message) async{
    Post? postToUpdate = await getPost(fastHash(message.id));

    if(postToUpdate != null){
      postToUpdate.payload = jsonEncode(message);
      updatePost(postToUpdate);
    }
  }

  Future<void> deletePost(int id) async {
    await database.writeTxn(() async{
      return await database.posts.delete(id);
    });
  }

  Future<void> clearPostsCollection() async {
    await database.writeTxn(() async {
      database.posts.clear();
    });
  }

//**************************** POST functions END
}