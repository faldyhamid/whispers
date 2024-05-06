import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:whispers/post.dart';
import 'package:whispers/user.dart';
import 'package:whispers/utils.dart';

class ConversationList extends StatefulWidget{
  final int index;
  final User user;
  final Post? lastPost;
  final Function(int) onTap;
  final Function(int) onLongPress;
  late final lastMessage = lastPost?.payload != null ? jsonDecode(lastPost!.payload!) : {'status': 'seen', 'text': ''};
  late final bool isMessageRead = lastMessage?['status'] == 'seen' ? false : true;

  ConversationList({super.key, required this.index, required this.user, this.lastPost,
    required this.onTap, required this.onLongPress});

  @override
  State<ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends State<ConversationList> {
  @override
  Widget build(BuildContext context) {
    print('Building ${initName(widget.user)}');
    return GestureDetector(
      onTap: (){
        widget.onTap(widget.index);
      },
      onLongPress: (){
        widget.onLongPress(widget.index);
      },
      child: Container(
        padding: EdgeInsets.only(left: 16,right: 16,top: 10,bottom: 10),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    backgroundImage: NetworkImage(widget.user.imageUrl ?? ''),
                    maxRadius: 30,
                  ),
                  SizedBox(width: 16,),
                  Expanded(
                    child: Container(
                      color: Colors.transparent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(initName(widget.user), style: TextStyle(fontSize: 16),),
                          SizedBox(height: 6,),
                          Text(widget.lastMessage?['text'],style: TextStyle(fontSize: 13,color: Colors.grey.shade600, fontWeight: widget.isMessageRead?FontWeight.bold:FontWeight.normal),),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(getVerboseDateTimeRepresentation(DateTime.fromMillisecondsSinceEpoch(widget.lastPost?.createAt ?? widget.user.createAt)),style: TextStyle(fontSize: 12,fontWeight: widget.isMessageRead?FontWeight.bold:FontWeight.normal),),
          ],
        ),
      ),
    );
  }
}