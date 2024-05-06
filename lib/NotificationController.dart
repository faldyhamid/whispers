import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:whispers/post.dart';
import 'package:whispers/user.dart';

import 'ChatPage.dart';
import 'HomePage.dart';
import 'isar_manager.dart';
import 'main.dart';

class NotificationController {
  static ReceivedAction? initialAction;
  static const bool _initialised = false;

  static Future<void> handleBackgroundAction(ReceivedAction receivedAction) async {
    if (receivedAction.channelKey == 'message_channel') {
      User user = User.fromJson(jsonDecode(receivedAction.payload!['user']!) as Map<String, dynamic>);


      navigatorKey.currentState?.pushNamedAndRemoveUntil('/chatpage',
              (route) => (route.settings.name != '/chatpage') || route.isFirst,
          arguments: user);
    }
  }

  static Future<void> initializeLocalNotifications() async {
    ReceivePort port = ReceivePort();
    IsolateNameServer.registerPortWithName(
      port.sendPort,
      'background_notification_action',
    );

    port.listen((var received) async {
      handleBackgroundAction(received);
    });

    //_initialized = true;

    AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'message_channel',
          channelName: 'New Messages',
          channelDescription: 'Used to send notifications of scheduled messages',
          defaultColor: Colors.blue,
          importance: NotificationImportance.High,
          groupAlertBehavior: GroupAlertBehavior.Summary,
          channelShowBadge: true,
          enableVibration: true,
          enableLights: true,
        ),
      ],
    );

    initialAction = await AwesomeNotifications()
        .getInitialNotificationAction(removeFromActionEvents: false);
  }

  static Future<void> startListeningNotificationEvents() async {
    AwesomeNotifications()
        .setListeners(onActionReceivedMethod: onActionReceivedMethod);
  }

  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future <void> onNotificationCreatedMethod(ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future <void> onNotificationDisplayedMethod(ReceivedNotification receivedNotification) async {
    // Your code goes here
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future <void> onDismissActionReceivedMethod(ReceivedAction receivedAction) async {
    // Your code goes here
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future <void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    if (!_initialised) {
      SendPort? uiSendPort = IsolateNameServer.lookupPortByName('ui_action');
      if (uiSendPort != null) {
        uiSendPort.send(receivedAction);
        return;
      }
    }

    await handleBackgroundAction(receivedAction);
  }
}