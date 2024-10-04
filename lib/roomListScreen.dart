import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart'as http;
import 'package:http/http.dart';
import 'package:http/http.dart';
import 'package:send_message/usersModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  GetUsers selectedUser=GetUsers();
  bool isConversationRequested = false;
  List<String>membersOnline=[];
  Map<String?, bool> userStatusMap = {};
  late String currentUser;
  @override
  void initState() {
    super.initState();
    loadUserId();
    print("This is User Id on Room List Screen${widget.currentUserId}");
    socket = IO.io('ws://192.168.43.100:3001', IO.OptionBuilder()
        .setTransports(['websocket'])
        .build());

    socket.connect();

    socket.onConnect((_)  {
      print('Connected to the server(RoomListScreen)');
      socket.emit('getAllUsers');
      print("@@@@@@@@@@Current user id inside on connect@@@@@@@@@@@@@: ${widget.currentUserId}");
      socket.emit("userOnline",[ widget.currentUserId]);
      updateUser();
    });
    getAllUser();
    receiveConversation();
  }
  void updateUser(){
    socket.on("updateUserStatus",(data){
      Map onlineUsers=data["onlineUsers"];
      membersOnline.clear();
      onlineUsers.forEach((key,value){
        if(value!=null){
          membersOnline.add(key);
          print("members that online:$membersOnline");
        }
      });
      setState(() {
        for (var user in users) {
          userStatusMap[user.sId] = membersOnline.contains(user.sId);
        }
      });
      print("This is Update User status Dat$data");
    });
  }
  void getAllUser(){
    socket.on('getAllUsers', (data) {
      print('Received all users: $data');
      setState(() {
        users = (data as List).map((json) => GetUsers.fromJson(json)).toList();
        userStatusMap = {};
        for (var user in users) {
          userStatusMap[user.sId] = membersOnline.contains(user.sId);
        }
      });
      print('User Status Map List on mySide: $userStatusMap');
    });
  }
  void receiveConversation(){
    socket.on('receiveConversation', (data) {
      print("********Received data from receiveConversation:********* $data");
      List  members = data['members'];
      if(members.contains(widget.currentUserId)){
        if (data is Map && data.containsKey('_id')) {
          setState(() {
            conversationId = data['_id'];
          });
          // print("Conversation ID: $conversationId");

        } else {
          print("Unexpected data format. Expected a Map.");
        }
        socket.emit("joinConversation",conversationId);
        // room(widget.currentUserId,selectedUser.sId);

      }
    });
  }
  Future<void> loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUser = prefs.getString('userId')!;

    });
    print("Loaded userId from SharedPreferences: $currentUser");
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

  void navigateToChatScreen(String conversationId) {
    print('Navigating to ChatScreen with conversationId: $conversationId');
    // if (conversationId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            username: selectedUser.name ?? "unknown",
            senderId: widget.currentUserId,
            receiverId: selectedUser.sId ?? "null",
            conversationId: conversationId,
          ),
        ),
      ).then((_) {
        setState(() {
          selectedUser = GetUsers();
          isConversationRequested = false;
        });
      });
    // } else {
    //   print('Error: Conversation ID is null');
    // }
  }
  void room(String senderId,String? receiverId) async {
    try {
      http.Response response = await http.post(
        Uri.parse("http://192.168.43.100:3001/api/conversation/get"),
        headers: {
          'Content-Type': 'application/json',
        },
        body:json.encode( {
          "senderId":senderId,
          "receiverId":receiverId,
        }),
      );
      if (response.statusCode == 200) {
        print(response.body);
        var data = jsonDecode(response.body);
        String conversationId = data['_id'];
        print("Got ConversationId ${conversationId}");
        navigateToChatScreen(conversationId);
      } else {
        print('Failed to log in: ${response}');
      }
    } catch (e) {
      print("This is Error: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contacts'),
        backgroundColor: Colors.blueAccent,
        automaticallyImplyLeading: false,
      ),
      body: users.isEmpty
          ? Center(
        child: CircularProgressIndicator(),
      )
          : ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          if (user.sId == widget.currentUserId) return SizedBox.shrink();

          bool isUserOnline = userStatusMap[user.sId] ?? false;
          return ListTile(
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.transparent,
              backgroundImage: AssetImage("assets/person.jpg"), // Placeholder image
            ),
            title: Text(
              user.name ?? "No Name",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              isUserOnline ? "Online" : "Offline",
              style: TextStyle(
                color: isUserOnline ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              selectedUser = user;
              newConversation(widget.currentUserId, user.sId.toString());
              room(widget.currentUserId, user.sId);
            },
          );
        },
      ),
    );
  }

}