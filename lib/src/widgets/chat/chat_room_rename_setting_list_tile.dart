import 'package:fireflutter/fireflutter.dart';
import 'package:fireflutter/src/models/chat_room_model.dart';
import 'package:flutter/material.dart';

class RenameChatRoomSettingTile extends StatelessWidget {
  RenameChatRoomSettingTile({
    super.key,
    required this.room,
  });

  final ChatRoomModel room;

  final chatRoomName = TextEditingController();

  @override
  Widget build(BuildContext context) {
    chatRoomName.text = room.rename[UserService.instance.uid] ?? '';
    return ListTile(
      title: const Text("Rename Chat Room"),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("This will rename the chat room only on your view."),
          TextFormField(
            controller: chatRoomName,
            textInputAction: TextInputAction.done,
            decoration:
                const InputDecoration(hintText: 'Enter the chat room name.'),
            onFieldSubmitted: (value) async {
              if (value.isNotEmpty) {
                await ChatService.instance.updateRoomSetting(
                  room: room,
                  setting: 'rename',
                  value: {UserService.instance.uid: value},
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
