import 'dart:convert';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:intl/intl.dart';
import 'package:whispers/post.dart';
import 'package:whispers/user.dart';

import 'NotificationController.dart';
import 'isar_manager.dart';

int fastHash(String string) {
  var hash = 0xcbf29ce484222325;

  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }

  return hash;
}

String initName(User user){
  String combine = '';

  if(user.firstName != null && user.lastName != null){
    combine += '${user.firstName} ${user.lastName}';
  }
  else if(user.firstName != null){
    combine += user.firstName!;
  }
  else{
    combine += user.lastName!;
  }

  return combine;
}

String getVerboseDateTimeRepresentation(DateTime dateTime) {
  DateTime now = DateTime.now();
  DateTime justNow = DateTime.now().subtract(Duration(minutes: 1));
  DateTime localDateTime = dateTime.toLocal();

  if (!localDateTime.difference(justNow).isNegative) {
    return 'Just now';
  }

  String roughTimeString = DateFormat('jm').format(dateTime);
  if (localDateTime.day == now.day && localDateTime.month == now.month && localDateTime.year == now.year) {
    return roughTimeString;
  }

  DateTime yesterday = now.subtract(const Duration(days: 1));

  if (localDateTime.day == yesterday.day && localDateTime.month == yesterday.month && localDateTime.year == yesterday.year) {
    return 'Yesterday, $roughTimeString';
  }

  if (now.difference(localDateTime).inDays < 4) {
    String weekday = DateFormat('EEEE').format(localDateTime);

    return '$weekday, $roughTimeString';
  }

  return '${DateFormat('yMd').format(dateTime)}, $roughTimeString';
}

Future<void> handleScheduledMessage(int id) async{
  await isarManager.handleIsar();
  // Only after at least the action method is set, the notification events are delivered
  NotificationController.startListeningNotificationEvents();

  Post? post = await isarManager.getPost(id);

  if(post != null){
    User? user = await isarManager.getUser(post.userId!);
    post.createAt = post.schedule;
    print('${post.createAt} and Schedule ${post.schedule}');
    post.status = 1;
    user?.lastSeen = post.createAt;

    await isarManager.updatePost(post);
    await isarManager.updateUser(user!);

    await createMessageNotification(user, post);
  }
  else{
  }
}

Future<void> createMessageNotification(user, post) async {
  final message = jsonDecode(post.payload!);

  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: user.isarId.toSigned(32),
      channelKey: 'message_channel',
      groupKey: user.isarId.toString(),
      title: initName(user),
      body: message['text'],
      summary: 'New Message',
      largeIcon: user.imageUrl,
      bigPicture: user.imageUrl,
      roundedLargeIcon: true,
      roundedBigPicture: true,
      wakeUpScreen: true,
      payload: <String, String>{
        'user': jsonEncode(user),
      },
      category: NotificationCategory.Message,
      notificationLayout: NotificationLayout.Messaging
    ),
  );
}

