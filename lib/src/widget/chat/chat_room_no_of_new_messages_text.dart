import 'package:fireflutter/src/model/room.dart';
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';

class ChatRoomNoOfNewMessageBadgesText extends StatelessWidget {
  const ChatRoomNoOfNewMessageBadgesText({
    super.key,
    required this.room,
  });

  final Room room;

  @override
  Widget build(BuildContext context) {
    final String noOfNewMessagesText = room.noOfNewMessages[FirebaseAuth.instance.currentUser!.uid] != null
        ? '${room.noOfNewMessages[FirebaseAuth.instance.currentUser!.uid]} unread messages'
        : '';
    return Text(noOfNewMessagesText);
  }
}
