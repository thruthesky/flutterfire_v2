import 'package:fireflutter/fireflutter.dart';
import 'package:flutter/material.dart';

class ChatCustomize {
  final Widget Function(ChatModel chat)? chatRoomMenu;

  final Widget Function(ChatRoom chatRoom)? chatRoomInviteButton;

  const ChatCustomize({
    this.chatRoomMenu,
    this.chatRoomInviteButton,
  });
}
