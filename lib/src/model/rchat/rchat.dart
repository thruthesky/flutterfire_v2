import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_ui_database/firebase_ui_database.dart';
import 'package:fireflutter/fireflutter.dart';
import 'package:path/path.dart';

/// RChat
///
class RChat {
  /// Firebase Realtime Database Chat Functions
  ///
  ///
  ///
  static DatabaseReference get roomsRef => rtdb.ref().child('chat-rooms');
  static DatabaseReference roomRef(String uidA, String uidB) => rtdb.ref().child('chat-rooms/$uidA/$uidB');
  static DatabaseReference messageRef({required String roomId}) => rtdb.ref().child('chat-messages').child(roomId);

  /// [groupUserRef] is the reference to the users node under the group chat room. Ex) /chat-rooms/{roomId}/users
  static DatabaseReference groupUserRef(String roomId) => rtdb.ref().child('chat-rooms/$roomId/users');

  /// 각 채팅방 마다 -1을 해서 order 한다.
  ///
  /// 더 확실히 하기 위해서는 order 를 저장 할 때, 이전 order 의 -1 로 하고, 저장이 된 후, createAt 의 -1 을 해 버린다.
  static final Map<String, int> roomMessageOrder = {};

  /// Set the current room.
  static RChatRoomModel? _currentRoom;
  static RChatRoomModel get currentRoom => _currentRoom!;
  static setCurrentRoom(RChatRoomModel room) => _currentRoom = room;

  /// 채팅 메시지 전송
  ///
  ///
  static Future<void> sendMessage({
    String? text,
    String? url,
  }) async {
    if ((url == null || url.isEmpty) && (text == null || text.isEmpty)) return;

    if (my?.isDisabled == true) {
      toast(title: 'Notice', message: 'Your account is disabled. Please contact admin.');
      return;
    }

    roomMessageOrder[currentRoom.messageRoomId] = (roomMessageOrder[currentRoom.messageRoomId] ?? 0) - 1;

    /// 참고, 실제 메시지를 보내기 전에, 채팅방 자체를 먼저 업데이트 해 버린다.
    ///
    /// 상황 발생, A 가 B 가 모두 채팅방에 들어가 있는 상태에서
    /// A 가 B 에게 채팅 메시지를 보내면, 그 즉시 B 의 채팅방 목록이 업데이트되고,
    /// B 의 채팅방의 newMessage 가 0 으로 된다.
    /// 그리고, 나서 updateRoom() 을 하면, B 의 채팅 메시지가 1이 되는 것이다.
    /// 즉, 0이 되어야하는데 1이 되는 상황이 발생한다. 그래서, updateRoom() 이 먼저 호출되어야 한다.
    updateRoom(text: text, url: url);

    await messageRef(roomId: currentRoom.messageRoomId).push().set({
      'uid': myUid,
      if (text != null) 'text': text,
      if (url != null) 'url': url,
      'order': RChat.roomMessageOrder[currentRoom.messageRoomId],
      'createdAt': ServerValue.timestamp,
    });
  }

  /// see rchat.md
  ///
  /// [receiverUid] is the one who will receive the message.
  static Future<Map<String, dynamic>> _lastMessage({
    required String receiverUid,
    String? text,
    String? url,
    int? newMessage,
  }) async {
    String name;
    if (currentRoom.isGroupChat) {
      name = currentRoom.name ?? '';
    } else {
      if (receiverUid == myUid) {
        final user = await UserService.instance.get(receiverUid);
        name = user?.name ?? 'Receiver has no name';
      } else {
        name = my?.name ?? 'Sender has no name';
      }
    }
    return {
      'name': name,
      'text': text,
      'url': url,
      'updatedAt': ServerValue.timestamp,
      'newMessage': newMessage ?? ServerValue.increment(1),
      'isGroupChat': currentRoom.isGroupChat,
      'isOpenGroupChat': currentRoom.isOpenGroupChat,
    };
  }

  /// 나의 채팅방 정보와 상대방의 채팅방 정보를 업데이트한다.
  ///
  /// 그룹 챗방에서는, 채팅방에 있는 모든 사용자의 채팅방 목록을 업데이트 한다.
  /// 즉, 이 함수에서는 그룹 채팅의 경우, 그룹 채팅방 정보를 업데이트하지는 않는다.
  static Future<void> updateRoom({
    String? text,
    String? url,
  }) async {
    /// 일대일 채팅방의 경우, 나와 상대방의 메시지 업데이트
    if (currentRoom.isSingleChat) {
      /// Update last chat message under my chat room list
      roomRef(myUid!, currentRoom.id).set(
        await _lastMessage(
          receiverUid: myUid!,
          text: text,
          url: url,
          newMessage: 0,
        ),
      );

      // chat room info update under other user room list
      roomRef(currentRoom.id, myUid!).update(
        await _lastMessage(
          receiverUid: currentRoom.id,
          text: text,
          url: url,
        ),
      );
    } else {
      /// 그룹 채팅방의 경우, 모든 사용자(나를 포함)의 채팅방 목록을 업데이트 한다.
      ///
      for (final e in currentRoom.users?.entries.toList() ?? []) {
        dog('user uid: ${e.key}');
        final uid = e.key;
        roomRef(uid, currentRoom.id).update(
          await _lastMessage(
            receiverUid: uid,
            text: text,
            url: url,
            newMessage: uid == myUid ? 0 : null,
          ),
        );
      }
    }
  }

  /// 채팅방 나가기
  ///
  /// 상대방의 채팅방 목록에서는 삭제하지 않고, 나의 채팅방 목록에서만 삭제한다.
  /// 즉, 상대방은 모르게 한다.
  ///
  /// For 1:1 chat, just remove the chat room node from /chat-rooms/{myUid}/{otherUid}
  /// For group chat, remove the chat room node from /chat-rooms/{myUid}/{groupChatId}
  ///   and remove my uid from /chat-rooms/{gropChatId}/users/{myUid}
  static leaveRoom({
    required RChatRoomModel room,
  }) {
    if (room.isGroupChat == true) {
      /// 그룹 채팅방에서 나가기
      leaveGroupChat(room: room);
    } else {
      /// 1:1 채팅방에서 나가기
      leaveSingleChat(room: room);
    }
  }

  static leaveGroupChat({required RChatRoomModel room}) {
    /// 그룹 채팅방에서 나가기
    roomRef(myUid!, room.key).remove();
    groupUserRef(room.key).child(myUid!).remove();
  }

  static leaveSingleChat({required RChatRoomModel room}) {
    /// 1:1 채팅방에서 나가기
    roomRef(myUid!, room.key).remove();
  }

  /// 채팅방의 메시지 순서(order)를 담고 있는 [RChat.roomMessageOrder] 를 초기화 한다.
  static resetRoomMessageOrder({required String roomId, required int? order}) async {
    if (RChat.roomMessageOrder[roomId] == null) {
      RChat.roomMessageOrder[roomId] = 0;
    }
    if (order != null && order < RChat.roomMessageOrder[roomId]!) {
      RChat.roomMessageOrder[roomId] = order;
    }
  }

  /// 채팅방의 메시지 순서(order)를 가져온다.
  /// 만약, [RChat.roomMessageOrder] 에 값이 없으면 0을 리턴한다.
  static int getRoomMessageOrder(String messageRoomId) {
    return RChat.roomMessageOrder[messageRoomId] ?? 0;
  }

  /// 채팅방 정보 `/chat-rooms/$uid/$otherUid` 에서 newMessage 를 0 으로 초기화 한다.
  ///
  /// 특히, 내가 채팅방에 들어가 갈 때, 또는 내가 채팅방에 들어가 있는데, 새로운 메시지가 전달되어져 오는 경우,
  /// 이 함수가 호출되어 그 채팅방의 새 메시지 수를 0으로 초기화 할 때 사용한다.
  static Future<void> resetMyRoomNewMessage({required RChatRoomModel room}) async {
    await roomRef(myUid!, room.id).update(
      {
        'newMessage': 0,
      },
    );
    // print('--> resetRoomNewMessage: $roomId');
  }

  /// 누군가 채팅을 해서, 새로운 메시지가 전달되어져 왔는지 판단하는 함수이다.
  ///
  /// 채팅방 목록을 하는 [RChatMessageList] 에서 사용 할 수 있으며, 새로운 메시지가 전달되었으면, newMessage 를
  /// 0 으로 저장해야 할 지, 판단하는 함수이다.
  ///
  /// [messageRoomId] 는 채팅 메시지를 저장하는 노드 ID(채팅방 ID가 아님),
  ///
  /// [snapshot] 은 채팅방 안에서, 페이지 단위로 채팅을 로딩 할 때, 그 채팅 노드를 담고 있는
  /// [FirebaseDatabaseQueryBuilder] 의 snapshot 이다.
  /// 처음 채팅방 접속 또는 채팅방을 위로 스크롤 할 때, 또는 누군가 새로운 채팅을 할 때, 새로운 채팅 목록 정보를 가져와서
  /// 화면에 보여줄 때, 이 함수가 호출된다. 이 때, [snapshot] 이 그 채팅 메시지 목록을 가지고 있다.
  ///
  ///
  /// 이 함수는, 누군가 채팅을 해서, 새로운 메시가 전달되었다면 true 를 리턴한다. 화면 스크롤이나, 처음 채팅방 접속해서
  /// 채팅 메시지를 가져오는 경우에는 false 를 리턴한다.
  ///
  /// 처음 로딩(첫 페이지)하거나, Hot reload 를 하거나, 채팅방을 위로 스크롤 업 해서 이전 데이터 목록을 가져오는 경우에는
  /// false 를 리턴한다.
  ///
  /// 채팅방에 들어가 있는 상태에서 새로운 메시지를 받으면, "newMessage: 를 0 으로 초기화 하기 위해서이다. 즉,
  /// 채팅 메시지를 읽음으로 표시하기 위해서이다.
  ///
  /// 문제, 앱을 처음 실행하면, [chatRoomMessgaeOrder] 에는 아무런 값이 없다. 이 때, 새로운 메시지가 있는
  /// 채팅방으로 접속을 하면, `if (currentMessageOrder == 0 ) return fales` 에 의해서 항상 false 가
  /// 리턴된다. 그래서, 처음 채팅방에 진입을 할 때에는 [snapshot.isFetching] 을 통해서 newMessage 를 초기화
  /// 해야 한다.
  static bool isLoadingNewMessage(String messageRoomId, FirebaseQueryBuilderSnapshot snapshot) {
    if (snapshot.docs.isEmpty) return false;

    final lastMessage = RChatMessageModel.fromSnapshot(snapshot.docs.first);
    final lastMessageOrder = lastMessage.order as int;

    final currentMessageOrder = getRoomMessageOrder(messageRoomId);

    /// 이전에 로드된 채팅 메시지가 없는가? 누군가 채팅을 한 것이 아니라, 채팅방에 접속해서, 처음 로드된 것이므로 false 를 리턴한다.
    if (currentMessageOrder == 0) {
      return false;
    }

    /// 이전에 로드된 채팅 메시지가 있는가?
    /// 그렇다면 이전에 로드된 채팅 메시지의 order 와 현재 로드된 채팅 메시지의 order 를 비교한다.
    /// 만약 이전에 로드된 채팅 메시지의 order 가 현재 로드된 채팅 메시지의 order 보다 크다면,
    /// 누군가 채팅을 해서 새로운 메시지가 있다는 것이다.
    if (currentMessageOrder > lastMessageOrder) {
      return true;
    }

    /// 이전에 로드된 채팅 메시지가 있지만, 새로운 채팅 메시지를 받지 않았다면, false 를 리턴한다.
    /// 위로 스크롤 하는 경우, 이 메시지가 발생 할 수 있다.
    return false;
  }

  /// For group chat, the user uid is added to /chat-rooms/{groupChatId}/users/{[uid]: true}
  /// For 1:1 chat, create a chat room info under my chat room list only. Not the other user's.
  ///
  /// Note, it's not that harmful to set the same uid to true over again and if it happens
  /// only one time when the user enters the chat room.
  ///
  ///
  static Future joinRoom({required RChatRoomModel room}) async {
    if (room.isGroupChat == true) {
      await set("${room.path}/users/$myUid", true);

      /// Add the group chat info under the login user's chat room list.
      await roomRef(myUid!, room.id).update({
        'name': room.name,
        'isGroupChat': true,
        'isOpenGroupChat': room.isOpenGroupChat,
        'updatedAt': ServerValue.timestamp,
        'newMessage': 0,
      });
    } else {
      await roomRef(myUid!, room.id).update({
        'isGroupChat': false,
        'isOpenGroupChat': false,
        'updatedAt': ServerValue.timestamp,
        'newMessage': 0,
      });
    }
  }

  static Future createRoom({
    required String name,
    required bool isGroupChat,
    required bool isOpenGroupChat,
  }) async {
    final room = await RChatRoomModel.create(
      name: name,
      isGroupChat: isGroupChat,
      isOpenGroupChat: isOpenGroupChat,
    );

    return room;
  }
} // EO RChat
