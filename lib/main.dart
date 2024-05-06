import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:whispers/HomePage.dart';
import 'package:whispers/ScheduledPage.dart';
import 'package:whispers/utils.dart';

import 'package:whispers/ChatPage.dart';
import 'package:workmanager/workmanager.dart';
import 'NotificationController.dart';
import 'isar_manager.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mime/mime.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:isar/isar.dart';
import 'post.dart';
import 'user.dart';

late final GlobalKey<NavigatorState> navigatorKey;

@pragma('vm:entry-point') // Mandatory if the App is obfuscated or using Flutter 3.1+
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch(task){
      case 'scheduledMessage':
        //simpleTask will be emitted here.
        await handleScheduledMessage(inputData?['Id']);
        break;
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  NotificationController.initializeLocalNotifications();
  // Only after at least the action method is set, the notification events are delivered
  NotificationController.startListeningNotificationEvents();
  Workmanager().initialize(
      callbackDispatcher, // The top level function, aka callbackDispatcher
      isInDebugMode: false // If enabled it will post a notification whenever the task is running. Handy for debugging tasks
  );

  initializeDateFormatting().then((_) => runApp(const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override initState(){
    navigatorKey = GlobalKey<NavigatorState>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) =>
      MaterialApp(
        title: 'Whisper',
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        routes: <String, WidgetBuilder>{
          '/chatpage': (context) => const ChatPage(),
          '/schedulepage': (context) => const ScheduledPage()
        },
        home: const HomePage(),
      );
}

