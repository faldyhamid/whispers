import 'dart:convert';
import 'dart:io';

import 'package:whispers/utils.dart';
import 'package:workmanager/workmanager.dart';

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
import 'package:date_field/date_field.dart';
import 'post.dart';
import 'user.dart';

class ScheduledPage extends StatefulWidget {
  const ScheduledPage({super.key});

  @override
  State<ScheduledPage> createState() => _ScheduledPageState();
}

class _ScheduledPageState extends State<ScheduledPage> {
  List<types.Message> _messages = [];
  List<Post> _scheduledPosts = [];

  late final User _chatUser = ModalRoute.of(context)!.settings.arguments as User;

  final _userA = const types.User(
    id: '82091008-a484-4a89-ae75-a22bf8d6f3ac',
    lastName: 'user',
  );

  late final _user = types.User(
      id: _chatUser.isarId.toString(),
      firstName: _chatUser.firstName,
      lastName: _chatUser.lastName,
      imageUrl: _chatUser.imageUrl
  );

  bool currentSide = false;
  int offSet = 0;
  late String lastSeen = getVerboseDateTimeRepresentation(DateTime.fromMillisecondsSinceEpoch(_chatUser.lastSeen!));

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _addMessage(types.Message message) {
    DateTime scheduledTime = DateTime.now();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('New Scheduled Message'),
          content: SingleChildScrollView(child:
            Column(
              children: [
                DateTimeFormField(
                decoration: const InputDecoration(
                hintStyle: TextStyle(color: Colors.black45),
                  errorStyle: TextStyle(color: Colors.redAccent),
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.event_note),
                  labelText: 'Scheduled Time',
                ),
                mode: DateTimeFieldPickerMode.dateAndTime,
                onDateSelected: (DateTime value) {
                  scheduledTime = value;
                },
              )]
            )
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if(_scheduledPosts.isNotEmpty){
                  _scheduledPosts.first.schedule == scheduledTime.millisecondsSinceEpoch ?
                      scheduledTime = scheduledTime.add(const Duration(seconds: 5)) :
                      scheduledTime;
                }

                message = message.copyWith(createdAt: scheduledTime.millisecondsSinceEpoch);

                Post post = Post(
                    id: message.id,
                    userId: int.parse(_user.id),
                    createAt: message.createdAt,
                    schedule: scheduledTime.millisecondsSinceEpoch,
                    status: 0,
                    payload: jsonEncode(message)
                );

                isarManager.insertPost(post);
                _scheduledPosts.insert(0, post);

                setState(() {
                  _messages.insert(0, message);
                });

                Workmanager().registerOneOffTask(
                  post.isarId.toString(),
                  'scheduledMessage',
                  inputData: <String, dynamic>{
                    'Id': post.isarId,
                  },
                  initialDelay: scheduledTime.difference(DateTime.now())
               );

                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 150,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleImageSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Photo'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleFileSelection();
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('File'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMessageLongPress(BuildContext _, types.Message message) {
    final index =
    _messages.indexWhere((element) => element.id == message.id);

    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 70,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                  DateTime.fromMillisecondsSinceEpoch(_scheduledPosts[index].schedule!).toString()
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleMessageDelete(message);
                  _scheduledPosts.removeAt(index);
                  setState(() {
                    _messages.removeAt(index);
                  });
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Delete'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMessageDelete(types.Message message) async{
    isarManager.deletePost(fastHash(message.id));
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final message = types.FileMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        mimeType: lookupMimeType(result.files.single.path!),
        name: result.files.single.name,
        size: result.files.single.size,
        uri: result.files.single.path!,
        status: types.Status.delivered,
      );

      _addMessage(message);
    }
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);

      final message = types.ImageMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        height: image.height.toDouble(),
        id: const Uuid().v4(),
        name: result.name,
        size: bytes.length,
        uri: result.path,
        width: image.width.toDouble(),
        status: types.Status.delivered,
      );

      _addMessage(message);
    }
  }

  void _handleMessageTap(BuildContext _, types.Message message) async {
    if (message is types.FileMessage) {
      var localPath = message.uri;

      if (message.uri.startsWith('http')) {
        try {
          final index =
          _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage =
          (_messages[index] as types.FileMessage).copyWith(
            isLoading: true,
          );

          setState(() {
            _messages[index] = updatedMessage;
          });

          final client = http.Client();
          final request = await client.get(Uri.parse(message.uri));
          final bytes = request.bodyBytes;
          final documentsDir = (await getApplicationDocumentsDirectory()).path;
          localPath = '$documentsDir/${message.name}';

          if (!File(localPath).existsSync()) {
            final file = File(localPath);
            await file.writeAsBytes(bytes);
          }
        } finally {
          final index =
          _messages.indexWhere((element) => element.id == message.id);
          final updatedMessage =
          (_messages[index] as types.FileMessage).copyWith(
            isLoading: null,
          );

          setState(() {
            _messages[index] = updatedMessage;
          });
        }
      }

      await OpenFilex.open(localPath);
    }
  }

  void _handlePreviewDataFetched(
      types.TextMessage message,
      types.PreviewData previewData,
      ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = (_messages[index] as types.TextMessage).copyWith(
      previewData: previewData,
    );

    setState(() {
      _messages[index] = updatedMessage;
    });
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
      status: types.Status.delivered,
    );

    _addMessage(textMessage);
  }

  Future<void> _handleEdgeScroll() async {
    final response = await isarManager.getActivePost(int.parse(_user.id), offSet);

    final messages = (response)
        .map((e) => types.Message.fromJson(jsonDecode(e.payload) as Map<String, dynamic>))
        .toList();

    offSet += 20;

    setState(() {
      _messages += messages;
    });
  }

  void _loadMessages() async {
    await isarManager.handleIsar();

    final response = await isarManager.getScheduledPost(int.parse(_user.id), offSet);
    offSet += 20;

    _scheduledPosts += response as List<Post>;

    final messages = (response)
        .map((e) => types.Message.fromJson(jsonDecode(e.payload!) as Map<String, dynamic>))
        .toList();

    setState(() {
      _messages += messages;
    });
  }

  AppBar _handleHeader() {
    return AppBar(
      elevation: 0,
      automaticallyImplyLeading: false,
      backgroundColor: neutral0,
      flexibleSpace: SafeArea(
        child: Container(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            children: <Widget>[
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back, color: neutral7,),
              ),
              const SizedBox(width: 2,),
              CircleAvatar(
                backgroundImage: NetworkImage(_chatUser.imageUrl ?? ''),
                maxRadius: 20,
              ),
              const SizedBox(width: 12,),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(initName(_chatUser), style: const TextStyle(
                        color: neutral7, fontSize: 16, fontWeight: FontWeight.w600),),
                    const SizedBox(height: 6,),
                    Text(lastSeen, style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13),),
                  ],
                ),
              ),
              const Icon(Icons.settings, color: neutral7,),

            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: _handleHeader(),
    body: Chat(
      messages: _messages,
      onAttachmentPressed: _handleAttachmentPressed,
      onMessageTap: _handleMessageTap,
      onMessageLongPress: _handleMessageLongPress,
      onPreviewDataFetched: _handlePreviewDataFetched,
      onSendPressed: _handleSendPressed,
      onEndReached: () => _handleEdgeScroll(),
      showUserAvatars: true,
      showUserNames: false,
      theme: const DefaultChatTheme(),
      user: _userA,
    ),
  );
}