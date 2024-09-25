import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:send_message/usersModel.dart';
import 'chat_screen.dart';
import 'dbMessages.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class RoomListScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;

  RoomListScreen({required this.currentUserId, required this.currentUserName});

  @override
  _RoomListScreenState createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  late IO.Socket socket;
  List<GetUsers> users = [];
  String? conversationId;
  late GetUsers selectedUser;

  @override
  void initState() {
    super.initState();
    socket = IO.io('ws://192.168.2.189:3001', IO.OptionBuilder()
        .setTransports(['websocket'])
        .build());

    socket.connect();

    socket.onConnect((_) {
      print('Connected to the server');
      socket.emit('getAllUsers');
    });

    socket.on('getAllUsers', (data) {
      print('Received all users: $data');
      setState(() {
        users = (data as List).map((json) => GetUsers.fromJson(json)).toList();
      });
    });

    socket.on('receiveConversation', (data) {
      print("********Received data from receiveConversation:********* $data");
      if (data is Map && data.containsKey('_id')) {
        setState(() {
          conversationId = data['_id'];
        });
        print("Conversation ID: $conversationId");
        navigateToChatScreen();  // Only navigate if there's a valid conversation ID
      } else {
        print("Unexpected data format. Expected a Map.");
      }
    });
  }

  void newConversation(String senderId, String receiverId) {
    socket.emit('newConversation', {
      'senderId': senderId,
      'receiverId': receiverId,
    });
    print("New conversation emitted: senderId: $senderId, receiverId: $receiverId");
  }

  void getConversation(String senderId, String receiverId) {
    socket.emit('getConversation', {
      'senderId': senderId,
      'receiverId': receiverId,
    });
    print("Get conversation emitted: senderId: $senderId, receiverId: $receiverId");
  }

  void navigateToChatScreen() {
    print('Navigating to ChatScreen with conversationId: $conversationId');
    if (conversationId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            username: selectedUser.name ?? "unknown",
            senderId: widget.currentUserId,
            receiverId: selectedUser.sId ?? "null",
            conversationId: conversationId!,
          ),
        ),
      ).then((_) {

        setState(() {
          selectedUser = GetUsers();
          conversationId = null;
        });
      });
    } else {
      print('Error: Conversation ID is null');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Chat Rooms", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: users.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          if (user.sId == widget.currentUserId) return SizedBox.shrink();
          return ListTile(
            title: Text(user.name ?? "No Name"),
            subtitle: Divider(),
            onTap: () {
              selectedUser = user;
              newConversation(widget.currentUserId, user.sId.toString());
              getConversation(widget.currentUserId, user.sId.toString());
            },
          );
        },
      ),
    );
  }
}
