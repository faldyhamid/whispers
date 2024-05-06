import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'ConversationList.dart';
import 'NotificationController.dart';
import 'isar_manager.dart';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'main.dart';
import 'post.dart';
import 'user.dart';

class HomePage extends StatefulWidget{
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _currentIndex = 0;
  final GlobalKey<_ChatListPageState> _key = GlobalKey();
  ReceivePort port = ReceivePort();

  @override
  void initState() {
    super.initState();

    IsolateNameServer.registerPortWithName(
      port.sendPort,
      'ui_action'
    );

    port.listen((var received) async {
      if (received.channelKey == 'message_channel') {
        NotificationController.handleBackgroundAction(received);
      }
    });

    AwesomeNotifications().isNotificationAllowed().then(
          (isAllowed) {
        if (!isAllowed) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Allow Notifications'),
              content: const Text('Allow notification for scheduled messages?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Don\'t Allow',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                ),
                TextButton(
                  onPressed: () => AwesomeNotifications()
                      .requestPermissionToSendNotifications()
                      .then((_) => Navigator.pop(context)),
                  child: const Text(
                    'Allow',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  void _handleSetting(BuildContext _) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  isarManager.clearPostsCollection();
                  isarManager.clearUsersCollection();

                  _key.currentState!.chatListCleared();
                  },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Clear'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _loadScreen() {
    switch(_currentIndex) {
      case 0: _key.currentState!.setState(() {});
      case 1: _handleSetting(context);
    }
  }

  BottomNavigationBar _handleBottomAppBar() {
    return BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap:(index){
          setState(() => _currentIndex = index);
          _loadScreen();
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: "Chats",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: _handleBottomAppBar(),
    body: ChatListPage(key: _key),
  );
}

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  List<User> _users = [];
  List<Post?> _lastPosts = [];
  late final Stream<List<Post>> _lastPostStream;
  late final _lastPostStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initialiseStreams();
  }

  @override
  void dispose() {
    _lastPostStreamSubscription.cancel();
    super.dispose();
  }

  void _initialiseStreams() async {
    await isarManager.handleIsar();
    if(_users.isEmpty){
      _loadUsers();
    }

    _lastPostStream = await isarManager.getLatestPostStream();
    _lastPostStreamSubscription = _lastPostStream.listen((e){
      setState(() {
        _lastPosts = e;
      });
    });
  }

  void _loadUsers() async {
   // _users.clear();
   // _lastPosts.clear();

    List<User> allUsers;

    allUsers = await isarManager.getUsers();

    _users = allUsers;

    await _loadLastPosts();
  }

  Future<void> _loadLastPosts() async {
    List<Post?> lastPosts = [];

    for(var user in _users){
      lastPosts.add(await isarManager.getLatestPost(user.isarId));
    }

    _handleNotificationStart();

    setState(() {
      _lastPosts = lastPosts;
    });
  }

  void _handleNotificationStart() async {
    ReceivedAction? receivedAction = await AwesomeNotifications().getInitialNotificationAction(
        removeFromActionEvents: true
    );

    if(receivedAction?.channelKey == 'message_channel') NotificationController.handleBackgroundAction(receivedAction!);
  }

  void _addUser() async {
    showDialog(
      context: context,
      builder: (_) {
        var firstNameController = TextEditingController();
        var lastNameController = TextEditingController();
        var imageUriController = TextEditingController();

        return AlertDialog(
          title: const Text('New Chat'),
          content: SingleChildScrollView(child:
            Column(
              children: [
                TextFormField(
                  controller: firstNameController,
                  decoration: const InputDecoration(hintText: 'First Name'),
                ),
                TextFormField(
                  controller: lastNameController,
                  decoration: const InputDecoration(hintText: 'Last Name'),
                ),
                TextFormField(
                  controller: imageUriController,
                  decoration: const InputDecoration(hintText: 'Avatar'),
                ),
              ],
            )
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                User newUser = User(
                    id: const Uuid().v4(),
                    createAt: DateTime.now().millisecondsSinceEpoch,
                    firstName: firstNameController.text,
                    lastName: lastNameController.text,
                    lastSeen: DateTime.now().millisecondsSinceEpoch,
                    imageUrl: imageUriController.text.isNotEmpty?
                                        imageUriController.text : dotenv.env['DEFAULT_AVATAR']
                );

                isarManager.insertUser(newUser);

                setState(() {
                  _users.insert(0, newUser);
                });

                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _editUser(int index) async {
    showDialog(
      context: context,
      builder: (_) {
        var firstNameController = TextEditingController();
        var lastNameController = TextEditingController();
        var imageUriController = TextEditingController();

        if(_users[index].firstName != null){
          firstNameController.text = _users[index].firstName!;
        }

        if(_users[index].lastName != null){
          lastNameController.text = _users[index].lastName!;
        }

        if(_users[index].imageUrl != null && _users[index].imageUrl != dotenv.env['DEFAULT_AVATAR']
        ){
          imageUriController.text = _users[index].imageUrl!;
        }

        return AlertDialog(
          title: const Text('New Chat'),
          content: SingleChildScrollView(child:
          Column(
            children: [
              TextFormField(
                controller: firstNameController,
                decoration: const InputDecoration(hintText: 'First Name'),
              ),
              TextFormField(
                controller: lastNameController,
                decoration: const InputDecoration(hintText: 'Last Name'),
              ),
              TextFormField(
                controller: imageUriController,
                decoration: const InputDecoration(hintText: 'Avatar'),
              ),
            ],
          )
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _users[index].firstName = firstNameController.text;
                _users[index].lastName = lastNameController.text;
                _users[index].imageUrl = imageUriController.text.isNotEmpty?
                imageUriController.text : dotenv.env['DEFAULT_AVATAR'];

                isarManager.updateUser(_users[index]);

                setState(() {
                  _users[index];
                });

                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void chatListCleared() {
    setState(() {
      _users = [];
      _lastPosts = [];
    });
  }

  void onUserTap(int index) async {
    _lastPostStreamSubscription.pause();

    await navigatorKey.currentState?.pushNamed(
      '/chatpage',
      arguments: _users[index]
    );

    _lastPostStreamSubscription.resume();

    /*
    Post? newLatestPost = await isarManager.getLatestPost(_users[index].isarId);

    setState(() {
      _lastPosts[index] = newLatestPost;
    });
    */
  }

  void onUserLongPress(int index) async {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: SizedBox(
          height: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  isarManager.deleteUser(_users[index].isarId);
                  isarManager.deleteActivePost(_users[index].isarId);

                  setState(() {
                    _users.removeAt(index);
                  });
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Delete'),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _editUser(index);
                },
                child: const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('Edit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
          <Widget>[
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 16,right: 16,top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text("Conversations",style: TextStyle(fontSize: 32,fontWeight: FontWeight.bold),),
                    Container(
                      padding: const EdgeInsets.only(left: 8,right: 8,top: 2,bottom: 2),
                      height: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.blue[50],
                      ),
                      child:
                      GestureDetector(
                        onTap: () => _addUser(),
                        child:
                        const Row(
                          children: <Widget>[
                            Icon(Icons.add,color: Colors.blue,size: 20,),
                            SizedBox(width: 2,),
                            Text("Add New",style: TextStyle(fontSize: 14,fontWeight: FontWeight.bold),),
                          ],
                        ),
                      )
                    )
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16,left: 16,right: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search...",
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: Icon(Icons.search,color: Colors.grey.shade600, size: 20,),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.all(8),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                          color: Colors.grey.shade100
                      )
                  ),
                ),
              ),
            ),
            _users.isNotEmpty
            ?ListView.builder(
              key: UniqueKey(),
              itemCount: _users.length,
              shrinkWrap: true,
              padding: const EdgeInsets.only(top: 16),
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index){
                return ConversationList(
                    key: UniqueKey(),
                    index: index,
                    user: _users[index],
                    lastPost: _lastPosts.firstWhere((element) => element?.userId == _users[index].isarId, orElse: () => Post(id:'0')),
                    onTap: onUserTap,
                    onLongPress: onUserLongPress
                );
              },
            )
            : const Center(child: Text(("It's oh so quiet..."))),
          ],
        ),
      ),
    );
  }
}